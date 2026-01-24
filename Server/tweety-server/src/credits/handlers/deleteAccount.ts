import { deleteUserAccount } from '../utils/db';

interface Env {
	tweety_credits: D1Database;
}

export async function deleteAccount(request: Request, env: Env): Promise<Response> {
	if (request.method !== 'DELETE') {
		return new Response('Method not allowed', { status: 405 });
	}

	try {
		// Get userId from X-User-Id header
		const userId = request.headers.get('X-User-Id');

		if (!userId) {
			return new Response(
				JSON.stringify({ error: 'Missing X-User-Id header' }),
				{ status: 400, headers: { 'Content-Type': 'application/json' } }
			);
		}

		await deleteUserAccount(userId, env);

		return new Response(
			JSON.stringify({
				success: true,
				userId,
				message: 'Account deleted successfully'
			}),
			{ headers: { 'Content-Type': 'application/json' } }
		);

	} catch (error) {
		console.error('Delete account error:', error);
		return new Response(
			JSON.stringify({
				error: 'Failed to delete account',
				details: error instanceof Error ? error.message : String(error)
			}),
			{ status: 500, headers: { 'Content-Type': 'application/json' } }
		);
	}
}
