//
//  XAuthService.swift
//  GrokMode
//
//  Created by Matt Steele on 12/7/25.
//

import Foundation
import AuthenticationServices
import CommonCrypto
import Combine

@Observable
class XAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {

    var isAuthenticated = false
    var currentUserHandle: String?
    
    private let callbackScheme = "grokmode"
    private var authSession: ASWebAuthenticationSession?
    
    // PKCE Components
    private var codeVerifier: String?
    
    // Config
    private var clientId: String {
        return Bundle.main.infoDictionary?["X_CLIENT_ID"] as? String ?? ""
    }
    
    // Storage
    private let tokenKey = "x_user_access_token"
    private let refreshTokenKey = "x_user_refresh_token"
    private let handleKey = "x_user_handle"
    private let tokenExpiryKey = "x_token_expiry_date"

    override init() {
        super.init()
        checkStatus()
    }

    func checkStatus() {
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            self.isAuthenticated = true
            self.currentUserHandle = UserDefaults.standard.string(forKey: handleKey)
        } else {
            self.isAuthenticated = false
        }
    }
    
    func login() {
        guard !clientId.isEmpty else {
            print("AUTH ERROR: Missing Client ID")
            return
        }

        // 1. Generate PKCE Verifier & Challenge
        let verifier = generateCodeVerifier()
        self.codeVerifier = verifier
        let challenge = generateCodeChallenge(from: verifier)

        // 2. Build Auth URL
        // https://twitter.com/i/oauth2/authorize?response_type=code&client_id=...&redirect_uri=...&scope=...&state=...&code_challenge=...&code_challenge_method=S256

        var components = URLComponents(string: "https://twitter.com/i/oauth2/authorize")!
        let state = UUID().uuidString
        
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: "grokmode://"),
            URLQueryItem(name: "scope", value: "tweet.read tweet.write users.read dm.read dm.write offline.access"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        
        guard let authURL = components.url else { return }

        // 3. Start Session
        self.authSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { callbackURL, error in
            guard error == nil, let callbackURL = callbackURL else {
                print("Auth Error: \(error?.localizedDescription ?? "Unknown")")
                return
            }

            // 4. Handle Callback
            self.handleCallback(url: callbackURL)
        }
        
        self.authSession?.presentationContextProvider = self
        self.authSession?.start()
    }

    private func handleCallback(url: URL) {
        // Extract code
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
              let code = codeItem.value else {
            print("Auth Error: No code in callback")
            return
        }

        // 5. Exchange Code for Token
        exchangeCodeForToken(code: code)
    }
    
    private func exchangeCodeForToken(code: String) {
        guard let verifier = self.codeVerifier else { return }

        let url = URL(string: "https://api.twitter.com/2/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Basic Auth header usually required for confidential clients, but for Public Native clients (no secret safe),
        // X usually expects just Client ID in body or Basic Auth with Client ID as user and empty secret?
        // Actually for PKCE Public Client, we send client_id in body.
        // Let's try sending just body first.

        let bodyParams = [
            "code": code,
            "grant_type": "authorization_code",
            "client_id": clientId,
            "redirect_uri": "grokmode://",
            "code_verifier": verifier
        ]
        
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    // Parse Response
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let accessToken = json["access_token"] as? String {

                        let refreshToken = json["refresh_token"] as? String
                        let expiresIn = json["expires_in"] as? Int ?? 7200 // Default 2 hours

                        // Calculate expiry date
                        let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))

                        // Save Token
                        await MainActor.run {
                            UserDefaults.standard.set(accessToken, forKey: self.tokenKey)
                            UserDefaults.standard.set(expiryDate, forKey: self.tokenExpiryKey)
                            if let rt = refreshToken {
                                UserDefaults.standard.set(rt, forKey: self.refreshTokenKey)
                            }
                            self.isAuthenticated = true
                            self.fetchCurrentUser()
                        }
                    } else {
                        print("Auth Error: Invalid Response JSON")
                    }
                } else {
                    let err = String(data: data, encoding: .utf8)
                    print("Auth Token Exchange Failed: \(err ?? "?")")
                }
            } catch {
                print("Auth Network Error: \(error)")
            }
        }
    }
    
    func fetchCurrentUser() {
        guard let token = UserDefaults.standard.string(forKey: tokenKey) else { return }
        
        let url = URL(string: "https://api.twitter.com/2/users/me")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let username = dataObj["username"] as? String {
                    
                    await MainActor.run {
                        self.currentUserHandle = "@\(username)"
                        UserDefaults.standard.set(self.currentUserHandle, forKey: self.handleKey)
                    }
                }
            } catch {
                print("Failed to fetch user: \(error)")
            }
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: handleKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        self.isAuthenticated = false
        self.currentUserHandle = nil
    }

    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }

    /// Get a valid access token, refreshing if necessary
    func getValidAccessToken() async -> String? {
        // Check if token exists
        guard let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty else {
            print("No access token found - user needs to login")
            return nil
        }

        // Check if token is expired or about to expire (within 5 minutes)
        if isTokenExpired() {
            print("Access token expired - attempting refresh")
            let refreshed = await refreshAccessToken()
            if refreshed {
                return UserDefaults.standard.string(forKey: tokenKey)
            } else {
                print("Token refresh failed - user needs to re-authenticate")
                await MainActor.run {
                    self.logout()
                }
                return nil
            }
        }

        return token
    }

    /// Check if the current token is expired or about to expire
    private func isTokenExpired() -> Bool {
        guard let expiryDate = UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date else {
            // No expiry date stored, assume expired for safety
            return true
        }

        // Consider expired if within 5 minutes of expiry
        let bufferTime: TimeInterval = 300 // 5 minutes
        return Date().addingTimeInterval(bufferTime) >= expiryDate
    }

    /// Refresh the access token using the refresh token
    private func refreshAccessToken() async -> Bool {
        guard let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) else {
            print("No refresh token available")
            return false
        }

        let url = URL(string: "https://api.twitter.com/2/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
            "client_id": clientId
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["access_token"] as? String {

                    let newRefreshToken = json["refresh_token"] as? String
                    let expiresIn = json["expires_in"] as? Int ?? 7200
                    let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))

                    // Update stored tokens
                    await MainActor.run {
                        UserDefaults.standard.set(accessToken, forKey: self.tokenKey)
                        UserDefaults.standard.set(expiryDate, forKey: self.tokenExpiryKey)
                        if let rt = newRefreshToken {
                            UserDefaults.standard.set(rt, forKey: self.refreshTokenKey)
                        }
                    }

                    print("Token refreshed successfully")
                    return true
                }
            } else {
                let err = String(data: data, encoding: .utf8)
                print("Token refresh failed: \(err ?? "?")")
            }
        } catch {
            print("Token refresh error: \(error)")
        }

        return false
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
