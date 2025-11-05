//
//  TutorialHighlightModifier.swift
//  ExpenseTracker
//
//  Glowing border effect for tutorial highlights
//

import SwiftUI

struct TutorialHighlight: ViewModifier {
    let isHighlighted: Bool
    let glowColor: Color = Color(red: 0.173, green: 0.914, blue: 0.118) // Green glow like Android

    @State private var glowAlpha: Double = 0.8
    @State private var borderWidth: CGFloat = 3

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(glowColor.opacity(isHighlighted ? glowAlpha : 0), lineWidth: isHighlighted ? borderWidth : 0)
            )
            .shadow(
                color: isHighlighted ? glowColor.opacity(glowAlpha) : .clear,
                radius: isHighlighted ? 20 : 0,
                x: 0,
                y: 0
            )
            .onAppear {
                if isHighlighted {
                    startGlowAnimation()
                }
            }
            .onChange(of: isHighlighted) { newValue in
                if newValue {
                    startGlowAnimation()
                }
            }
    }

    private func startGlowAnimation() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            glowAlpha = 1.0
            borderWidth = 6
        }
    }
}

extension View {
    func tutorialHighlight(isHighlighted: Bool) -> some View {
        modifier(TutorialHighlight(isHighlighted: isHighlighted))
    }
}
