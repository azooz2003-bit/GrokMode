//
//  RootView.swift
//  GrokMode
//
//  Created by Abdulaziz Albahar on 12/7/25.
//

import SwiftUI

struct RootView: View {
    @State private var authService = XAuthService()

    var body: some View {
        Group {
            if authService.isAuthenticated {
                VoiceAssistantView(autoConnect: true, authService: authService)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                LoginView(authService: authService)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

#Preview {
    RootView()
}
