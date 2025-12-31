import { AppleTransaction } from '../types';
import { classifyTransaction } from '../utils/transactionClassifier';
import {
	getRemainingCredits,
	isTransactionProcessed,
	createUserIfNotExists
} from '../utils/db';

interface Env {
	tweety_credits: D1Database;
}

export async function syncTransactions(request: Request, env: Env): Promise<Response> {
	if (request.method !== 'POST') {
		return new Response('Method not allowed', { status: 405 });
	}

	try {
		const body = await request.json() as {
			transactions: AppleTransaction[];
		};

		const { transactions } = body;

		if (!transactions || transactions.length === 0) {
			return new Response(
				JSON.stringify({ error: 'No transactions provided' }),
				{ status: 400, headers: { 'Content-Type': 'application/json' } }
			);
		}

		// Get user_id from appAccountToken (same for all transactions)
		const userId = transactions[0].app_account_token;

		if (!userId) {
			return new Response(
				JSON.stringify({ error: 'Missing appAccountToken' }),
				{ status: 400, headers: { 'Content-Type': 'application/json' } }
			);
		}

		await createUserIfNotExists(userId, env);

		let newCreditsAdded = 0;
		let processedCount = 0;
		let skippedCount = 0;

		const insertStatements = [];

		// Sort transactions by purchase date to process in chronological order
		const sortedTransactions = transactions.sort((a, b) =>
		parseInt(a.purchase_date_ms) - parseInt(b.purchase_date_ms)
		);

		// Process transactions sequentially to ensure each sees correct history
		// This prevents race conditions where upgrade is classified as new subscription
		for (const transaction of sortedTransactions) {
			const alreadyProcessed = await isTransactionProcessed(
				transaction.transaction_id,
				env
			);

			if (alreadyProcessed) {
				skippedCount++;
				continue;
			}

			// Classify transaction and calculate credits using tier ratio
			const classification = await classifyTransaction(transaction, env);
			const creditsAmount = classification.creditsToGrant;

			const isTrial = transaction.is_trial_period === 'true';
			const revocationDate = transaction.revocation_date_ms
				? parseInt(transaction.revocation_date_ms)
				: null;

			// Use INSERT OR IGNORE to handle race conditions gracefully
			// If another request inserts same transaction_id, this will silently skip
			try {
				await env.tweety_credits.prepare(
					`INSERT OR IGNORE INTO receipts (
						user_id, transaction_id, original_transaction_id,
						product_id, credits_amount, purchase_date, is_trial_period,
						transaction_type, previous_product_id, revocation_date,
						revocation_reason, expiration_date, notes
					) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
				).bind(
					userId,
					transaction.transaction_id,
					transaction.original_transaction_id,
					transaction.product_id,
					creditsAmount,
					parseInt(transaction.purchase_date_ms),
					isTrial ? 1 : 0,
					classification.type,
					classification.previousProductId,
					revocationDate,
					transaction.revocation_reason || null,
					transaction.expiration_date_ms ? parseInt(transaction.expiration_date_ms) : null,
					classification.notes
				).run();

				// Only count as processed if insert succeeded (not ignored)
				const inserted = await isTransactionProcessed(transaction.transaction_id, env);
				if (inserted) {
					newCreditsAdded += creditsAmount;
					processedCount++;
				} else {
					skippedCount++;
				}
			} catch (error) {
				console.error(`Failed to insert transaction ${transaction.transaction_id}:`, error);
				// Continue processing other transactions
			}
		}

		const balance = await getRemainingCredits(userId, env);

		return new Response(
			JSON.stringify({
				success: true,
				userId,
				processedCount,
				skippedCount,
				newCreditsAdded,
				...balance
			}),
			{ headers: { 'Content-Type': 'application/json' } }
		);

	} catch (error) {
		console.error('Transaction sync error:', error);
		return new Response(
			JSON.stringify({
				error: 'Transaction sync failed',
				details: error instanceof Error ? error.message : String(error)
			}),
			{ status: 500, headers: { 'Content-Type': 'application/json' } }
		);
	}
}
