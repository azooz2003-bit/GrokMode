export interface Env {
    X_AI_API_KEY: string;
    X_API_KEY: string;
    APP_SECRET: string;
}

export default {
    async fetch(request: Request, env: Env, ctx: ExecutionContext):
Promise<Response> {
        const url = new URL(request.url);

        // Auth check
        const appSecret = request.headers.get('X-App-Secret');
        if (appSecret !== env.APP_SECRET) {
            return new Response('Unauthorized', { status: 401 });
        }

        // Get ephemeral token for Grok Voice API
        if (url.pathname === '/grok/v1/realtime/client_secrets') {
            const response = await
fetch('https://api.x.ai/v1/realtime/client_secrets', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${env.X_AI_API_KEY}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    expires_after: { seconds: 3600 }
                })
            });

            return new Response(response.body, {
                headers: { 'Content-Type': 'application/json' }
            });
        }

        // Proxy X API requests
        if (url.pathname.startsWith('/x/')) {
            const xPath = url.pathname.replace('/x/', '');
            return fetch(`https://api.x.com/2/${xPath}${url.search}`, {
                method: request.method,
                headers: {
                    'Authorization': `Bearer ${env.X_API_KEY}`,
                    'Content-Type': 'application/json'
                },
                body: request.method !== 'GET' ? request.body : undefined
            });
        }

        return new Response('Not found', { status: 404 });
    }
};
