//
//  AnimatedWaveformView.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/7/25.
//

import SwiftUI

struct AnimatedWaveformView: View {
    let animator: WaveformAnimator
    let barCount: Int?
    let barSpacing: CGFloat
    let barWidth: CGFloat
    let accentColor: Color
    let isAnimating: Bool
    let fillWidth: Bool

    init(
        animator: WaveformAnimator,
        barCount: Int? = nil,
        barSpacing: CGFloat = 4,
        barWidth: CGFloat = 3,
        accentColor: Color = .cyan,
        isAnimating: Bool = false,
        fillWidth: Bool = false
    ) {
        self.animator = animator
        self.barCount = barCount
        self.barSpacing = barSpacing
        self.barWidth = barWidth
        self.accentColor = accentColor
        self.isAnimating = isAnimating
        self.fillWidth = fillWidth
    }

    var body: some View {
        if fillWidth {
            GeometryReader { geometry in
                let calculatedBarCount = calculateBarCount(for: geometry.size.width)
                HStack(spacing: barSpacing) {
                    ForEach(0..<calculatedBarCount, id: \.self) { index in
                        RoundedRectangle(cornerRadius: barWidth / 2)
                            .fill(accentColor)
                            .frame(width: barWidth)
                            .frame(height: barHeight(for: index, totalBars: calculatedBarCount))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            let count = barCount ?? 5
            HStack(spacing: barSpacing) {
                ForEach(0..<count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: barWidth / 2)
                        .fill(accentColor)
                        .frame(width: barWidth, height: barHeight(for: index, totalBars: count))
                }
            }
        }
    }

    private func calculateBarCount(for width: CGFloat) -> Int {
        let totalSpacing = barWidth + barSpacing
        let count = Int(width / totalSpacing) - 1
        return max(5, count)
    }

    private func barHeight(for index: Int, totalBars: Int) -> CGFloat {
        let minHeight: CGFloat = 8
        let maxHeight: CGFloat = 40

        let amplitudeIndex = index % animator.amplitudes.count
        let amplitude = animator.amplitudes[amplitudeIndex]

        let height = minHeight + (maxHeight - minHeight) * amplitude

        return isAnimating ? height : minHeight
    }
}

#Preview {
    @Previewable @State var animator = WaveformAnimator()
    @Previewable @State var isAnimating = false

    ZStack {
        Color.white.ignoresSafeArea()

        VStack(spacing: 20) {
            Button {

            } label: {
                AnimatedWaveformView(
                    animator: animator,
                    barCount: 20,
                    accentColor: .white,
                    isAnimating: isAnimating,
                    fillWidth: false
                )
            }
            .background(.blue)


            Button("Toggle") {
                isAnimating.toggle()
                if isAnimating {
                    animator.startAnimating()
                } else {
                    animator.stopAnimating()
                }
            }

            Spacer()
        }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
