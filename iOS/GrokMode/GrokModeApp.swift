//
//  GrokModeApp.swift
//  GrokMode
//
//  Created by Abdulaziz Albahar on 12/6/25.
//

import SwiftUI
internal import os

@main
struct GrokModeApp: App {
    @State var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(authViewModel: authViewModel)
                .task {
                    await initializeStore()
                }
        }
    }

    private func initializeStore() async {
        do {
            AppLogger.store.info("Initializing StoreKit...")

            StoreKitManager.shared.startObservingTransactions()

            // Load products from App Store
            try await StoreKitManager.shared.loadProducts()

            // Process any unfinished transactions from previous sessions
            await StoreKitManager.shared.restoreAllTransactions()

            AppLogger.store.info("StoreKit initialized successfully")
        } catch {
            AppLogger.store.error("Failed to initialize StoreKit: \(error)")
        }
    }
}
