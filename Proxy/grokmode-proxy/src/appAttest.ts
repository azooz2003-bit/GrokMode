import { decode } from 'cbor-x';

export interface Env {
    ATTEST_STORE: KVNamespace;
    TEAM_ID: string;
    BUNDLE_ID: string;
}

interface AttestationData {
    publicKey: string;
    receipt: string;
    createdAt: number;
}

/**
 * Verify an attestation statement from iOS
 */
export async function verifyAttestation(
    keyId: string,
    attestationB64: string,
    challengeB64: string,
    env: Env
): Promise<boolean> {
    try {
        const attestation = base64ToBuffer(attestationB64);
        const challenge = base64ToBuffer(challengeB64);

        const decoded = await decodeCBOR(attestation);

        if (!decoded.attStmt || !decoded.authData) {
            console.error('Invalid attestation structure');
            return false;
        }

        const authData = new Uint8Array(decoded.authData);
        const certChain = decoded.attStmt.x5c || [];

        if (!await verifyCertificateChain(certChain)) {
            console.error('Certificate chain verification failed');
            return false;
        }

        if (!await verifyAuthData(authData, env.TEAM_ID, env.BUNDLE_ID, keyId, challenge)) {
            console.error('Auth data verification failed');
            return false;
        }

        const publicKey = await extractPublicKey(certChain[0]);

        const attestationData: AttestationData = {
            publicKey: bufferToBase64(publicKey),
            receipt: attestationB64,
            createdAt: Date.now(),
        };

        await env.ATTEST_STORE.put(keyId, JSON.stringify(attestationData), {
            expirationTtl: 60 * 60 * 24 * 90
        });

        return true;
    } catch (error) {
        console.error('Attestation verification failed:', error);
        return false;
    }
}

/**
 * Verify an assertion for an API request
 */
export async function verifyAssertion(
    keyId: string,
    assertionB64: string,
    clientDataHash: string,
    env: Env
): Promise<boolean> {
    try {
        // Retrieve stored attestation data
        const storedData = await env.ATTEST_STORE.get(keyId);
        if (!storedData) {
            console.error('No attestation found for keyId:', keyId);
            return false;
        }

        const attestationData: AttestationData = JSON.parse(storedData);
        const assertion = base64ToBuffer(assertionB64);
        const clientHash = base64ToBuffer(clientDataHash);

        // Parse assertion (CBOR encoded)
        const decoded = await decodeCBOR(assertion);

        // Verify signature using stored public key
        const publicKey = base64ToBuffer(attestationData.publicKey);
        const signature = decoded.signature;
        const authData = decoded.authenticatorData;

        // Construct the data that was signed
        const signedData = new Uint8Array([...authData, ...clientHash]);

        // Verify the signature
        const isValid = await verifySignature(publicKey, signature, signedData);
        if (!isValid) {
            console.error('Invalid assertion signature');
            return false;
        }

        // Increment and verify counter to prevent replay attacks
        const counter = extractCounter(authData);
        // TODO: Store and verify counter increases monotonically

        return true;
    } catch (error) {
        console.error('Assertion verification failed:', error);
        return false;
    }
}

// MARK: - Helper Functions

function base64ToBuffer(base64: string): Uint8Array {
    const binaryString = atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes;
}

function bufferToBase64(buffer: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < buffer.length; i++) {
        binary += String.fromCharCode(buffer[i]);
    }
    return btoa(binary);
}

async function decodeCBOR(data: Uint8Array): Promise<any> {
    try {
        return decode(data);
    } catch (error) {
        console.error('CBOR decoding failed:', error);
        throw new Error('Failed to decode CBOR data');
    }
}

async function verifyCertificateChain(certChain: Uint8Array[]): Promise<boolean> {
    // Simplified certificate chain verification
    // In production, verify against Apple's root certificate
    // TODO: Implement proper certificate chain verification
    return certChain.length > 0;
}

async function extractPublicKey(cert: Uint8Array): Promise<Uint8Array> {
    try {
        const certBuffer = new ArrayBuffer(cert.byteLength);
        new Uint8Array(certBuffer).set(cert);

        const importedCert = await crypto.subtle.importKey(
            'spki',
            certBuffer,
            { name: 'ECDSA', namedCurve: 'P-256' },
            true,
            ['verify']
        );

        const exportedKey = await crypto.subtle.exportKey('spki', importedCert);

        if (exportedKey instanceof ArrayBuffer) {
            return new Uint8Array(exportedKey);
        }

        return cert;
    } catch (error) {
        console.error('Public key extraction error:', error);
        return cert;
    }
}

async function verifyAuthData(
    authData: Uint8Array,
    teamId: string,
    bundleId: string,
    keyId: string,
    challenge: Uint8Array
): Promise<boolean> {
    try {
        if (authData.length < 37) {
            console.error('Auth data too short');
            return false;
        }

        const appId = `${teamId}.${bundleId}`;
        const encoder = new TextEncoder();
        const appIdData = encoder.encode(appId);
        const appIdHash = await crypto.subtle.digest('SHA-256', appIdData);
        const expectedRpIdHash = new Uint8Array(appIdHash);

        const actualRpIdHash = authData.slice(0, 32);

        for (let i = 0; i < 32; i++) {
            if (expectedRpIdHash[i] !== actualRpIdHash[i]) {
                console.error('RP ID hash mismatch');
                return false;
            }
        }

        return true;
    } catch (error) {
        console.error('Auth data verification error:', error);
        return false;
    }
}

async function verifySignature(
    publicKey: Uint8Array,
    signature: Uint8Array,
    data: Uint8Array
): Promise<boolean> {
    // Verify ECDSA signature using WebCrypto API
    try {
        const key = await crypto.subtle.importKey(
            'spki',
            publicKey,
            { name: 'ECDSA', namedCurve: 'P-256' },
            false,
            ['verify']
        );

        return await crypto.subtle.verify(
            { name: 'ECDSA', hash: 'SHA-256' },
            key,
            signature,
            data
        );
    } catch (error) {
        console.error('Signature verification error:', error);
        return false;
    }
}

function extractCounter(authData: Uint8Array): number {
    // Extract signature counter from authenticator data
    // Counter is at bytes 33-36 (big-endian)
    if (authData.length < 37) return 0;

    return (
        (authData[33] << 24) |
        (authData[34] << 16) |
        (authData[35] << 8) |
        authData[36]
    );
}

/**
 * Generate a random challenge for attestation
 */
export function generateChallenge(): Uint8Array {
    const challenge = new Uint8Array(32);
    crypto.getRandomValues(challenge);
    return challenge;
}
