//
//  ContentView.swift
//  GrokMode
//
//  Created by Abdulaziz Albahar on 12/6/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)

                Text("GrokMode")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                NavigationLink(destination: VoiceTestView()) {
                    Text("🎙️ Voice Test (XAI)")
                        .font(.title2)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    ContentView()
}
