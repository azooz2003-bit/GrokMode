//
//  SettingsView.swift
//  GrokMode
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    let onLogout: () async -> Void

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            List {
                // Logout Section
                Section {
                    Button {
                        Task {
                            await onLogout()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isPurchasing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
            }
        }
    }
}

#Preview {
    SettingsView(onLogout: {})
}
