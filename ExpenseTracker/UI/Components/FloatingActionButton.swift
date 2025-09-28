//
//  FloatingActionButton.swift
//  ExpenseTracker
//
//  Created by migration from Android FloatingActionButton.kt
//

import SwiftUI

struct CustomFloatingActionButton: View {
    let onClick: () -> Void
    let icon: String
    let contentDescription: String?

    init(
        onClick: @escaping () -> Void,
        icon: String = "plus",
        contentDescription: String? = "add_expense".localized
    ) {
        self.onClick = onClick
        self.icon = icon
        self.contentDescription = contentDescription
    }

    var body: some View {
        Button(action: onClick) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(AppColors.primaryOrange)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .accessibilityLabel(contentDescription ?? "")
        .buttonStyle(FloatingActionButtonStyle())
    }
}

struct FloatingActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(
                color: .black.opacity(0.3),
                radius: configuration.isPressed ? 6 : 4,
                x: 0,
                y: configuration.isPressed ? 3 : 2
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct CustomFloatingActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomFloatingActionButton(
                onClick: { print("Add expense tapped") }
            )

            CustomFloatingActionButton(
                onClick: { print("Edit tapped") },
                icon: "pencil",
                contentDescription: "Edit"
            )

            CustomFloatingActionButton(
                onClick: { print("Delete tapped") },
                icon: "trash",
                contentDescription: "Delete"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}