//
//  View+Ext.swift
//  GrokMode
//
//  Created by Abdulaziz Albahar on 12/28/25.
//

import SwiftUI

extension View {
    func simulateTextHeight(_ font: Font) -> some View {
        Text("|")
          .font(font)
          .opacity(0)
          .background(self)
    }
}
