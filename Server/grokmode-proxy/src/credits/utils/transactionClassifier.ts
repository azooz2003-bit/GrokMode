import { AppleTransaction } from '../types';
import { getCreditsForProduct, getPriceForProduct } from './pricing';

export type TransactionType =
	| 'NEW_SUBSCRIPTION'
	| 'RENEWAL'
	| 'UPGRADE'
	| 'DOWNGRADE'
	| 'RESUBSCRIPTION'
	| 'REFUND'
	| 'ONE_TIME_PURCHASE';

interface TransactionHistory {
	product_id: string;
	purchase_date: number;
	credits_amount: number;
	transaction_id: string;
	expiration_date?: number;
}

interface ClassificationResult {
	type: TransactionType;
	creditsToGrant: number;
	previousProductId: string | null;
	notes: string;
}

/**
 * Classify transaction type and calculate credits using tier ratio approach
 * Maintains same profit margin as target tier during upgrades
 */
export async function classifyTransaction(
	transaction: AppleTransaction,
	env: { tweety_credits: D1Database }
): Promise<ClassificationResult> {

	// Check if it's a refund first
	if (transaction.revocation_date_ms) {
		return await handleRefund(transaction, env);
	}

	// Check if one-time purchase (no expiration date means not a subscription)
	if (!transaction.expiration_date_ms) {
		return handleOneTimePurchase(transaction);
	}

	// Get transaction history for this subscription chain
	const history = await getTransactionHistory(
		transaction.original_transaction_id,
		env
	);

	// NEW SUBSCRIPTION - no history
	if (history.length === 0) {
		const credits = getCreditsForProduct(
			transaction.product_id,
			transaction.is_trial_period === 'true'
		);
		return {
			type: 'NEW_SUBSCRIPTION',
			creditsToGrant: credits,
			previousProductId: null,
			notes: 'First transaction in subscription chain'
		};
	}

	// Sort by purchase date to find most recent previous transaction
	history.sort((a, b) => a.purchase_date - b.purchase_date);
	const previousTransaction = history[history.length - 1];
	const currentPurchaseDate = parseInt(transaction.purchase_date_ms);

	// Check for resubscription (gap in service)
	if (previousTransaction.expiration_date) {
		const previousExpirationDate = previousTransaction.expiration_date;
		const gapInDays = (currentPurchaseDate - previousExpirationDate) / (1000 * 60 * 60 * 24);

		// Any positive gap means no active subscription = resubscription
		if (gapInDays > 0) {
			const credits = getCreditsForProduct(
				transaction.product_id,
				transaction.is_trial_period === 'true'
			);
			const gapDescription = gapInDays >= 1
				? `${Math.round(gapInDays)} day${Math.round(gapInDays) !== 1 ? 's' : ''}`
				: `${Math.round(gapInDays * 24 * 60)} minutes`;
			return {
				type: 'RESUBSCRIPTION',
				creditsToGrant: credits,
				previousProductId: previousTransaction.product_id,
				notes: `Resubscribed after ${gapDescription} gap (no active subscription)`
			};
		}
	}

	// RENEWAL - same product
	if (transaction.product_id === previousTransaction.product_id) {
		const credits = getCreditsForProduct(
			transaction.product_id,
			transaction.is_trial_period === 'true'
		);
		return {
			type: 'RENEWAL',
			creditsToGrant: credits,
			previousProductId: previousTransaction.product_id,
			notes: 'Regular renewal of same tier'
		};
	}

	// UPGRADE or DOWNGRADE - different product
	const currentCredits = getCreditsForProduct(transaction.product_id, false);
	const previousCredits = getCreditsForProduct(previousTransaction.product_id, false);

	if (currentCredits > previousCredits) {
		// UPGRADE - maintain target tier's profit margin on total revenue
		// Calculate days remaining and Apple's refund amount
		const previousExpirationDate = previousTransaction.expiration_date || 0;
		const daysRemaining = (previousExpirationDate - currentPurchaseDate) / (1000 * 60 * 60 * 24);
		const daysInCycle = 7; // Weekly subscriptions (production value)

		const previousPrice = getPriceForProduct(previousTransaction.product_id);
		const currentPrice = getPriceForProduct(transaction.product_id);

		// Apple's proration calculation
		const refundAmount = (previousPrice / daysInCycle) * daysRemaining;

		// Calculate total revenue after refunds
		const additionalRevenue = currentPrice - refundAmount;

		// Apply target tier's ratio to total revenue
		const tierRatio = currentCredits / currentPrice;
		const targetTotalCredits = additionalRevenue * tierRatio;

		// Subtract credits already given for previous tier
		const creditsForUpgrade = targetTotalCredits - previousCredits;

		return {
			type: 'UPGRADE',
			creditsToGrant: creditsForUpgrade,
			previousProductId: previousTransaction.product_id,
			notes: `Upgrade: Total revenue $${additionalRevenue.toFixed(2)} × ${tierRatio.toFixed(3)} ratio = $${targetTotalCredits.toFixed(2)} target, minus $${previousCredits.toFixed(2)} already given = $${creditsForUpgrade.toFixed(2)} credits`
		};
	} else {
		// DOWNGRADE - treat as renewal at lower tier (happens at renewal date, not immediately)
		// User paid full price for lower tier, so grant full credits
		const credits = getCreditsForProduct(transaction.product_id, false);
		return {
			type: 'DOWNGRADE',
			creditsToGrant: credits,
			previousProductId: previousTransaction.product_id,
			notes: `Downgrade from ${previousTransaction.product_id} to ${transaction.product_id}: granting full lower-tier credits ($${credits.toFixed(2)})`
		};
	}
}

/**
 * Get transaction history for a subscription chain
 * Ordered by purchase_date to ensure chronological processing
 */
async function getTransactionHistory(
	originalTransactionId: string,
	env: { tweety_credits: D1Database }
): Promise<TransactionHistory[]> {
	try {
		const result = await env.tweety_credits.prepare(
			`SELECT product_id, purchase_date, credits_amount, transaction_id, expiration_date
			 FROM receipts
			 WHERE original_transaction_id = ?
			 ORDER BY purchase_date ASC`
		).bind(originalTransactionId).all<TransactionHistory>();

		return result.results || [];
	} catch (error) {
		console.error(`Failed to get transaction history for ${originalTransactionId}:`, error);
		return [];
	}
}

/**
 * Handle refund transactions
 * Note: Refunds are for actual customer refunds, NOT for upgrades (which are handled by proration)
 */
async function handleRefund(
	transaction: AppleTransaction,
	env: { tweety_credits: D1Database }
): Promise<ClassificationResult> {
	try {
		// Find the original transaction that granted credits
		const original = await env.tweety_credits.prepare(
			'SELECT credits_amount FROM receipts WHERE transaction_id = ?'
		).bind(transaction.transaction_id).first<{ credits_amount: number }>();

		const creditsToDeduct = original?.credits_amount || 0;

		return {
			type: 'REFUND',
			creditsToGrant: -1 * creditsToDeduct,
			previousProductId: transaction.product_id,
			notes: `Refund (${transaction.revocation_reason || 'unknown reason'}): deducting $${creditsToDeduct.toFixed(2)}`
		};
	} catch (error) {
		console.error(`Failed to process refund for ${transaction.transaction_id}:`, error);
		// On error, don't grant or deduct credits
		return {
			type: 'REFUND',
			creditsToGrant: 0,
			previousProductId: transaction.product_id,
			notes: `Refund processing error: ${error}`
		};
	}
}

/**
 * Handle one-time credit purchases
 */
function handleOneTimePurchase(
	transaction: AppleTransaction
): ClassificationResult {
	const credits = getCreditsForProduct(transaction.product_id, false);
	return {
		type: 'ONE_TIME_PURCHASE',
		creditsToGrant: credits,
		previousProductId: null,
		notes: 'One-time credit purchase'
	};
}
