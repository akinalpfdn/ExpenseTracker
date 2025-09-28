//
//  EditCategoryDialog.swift
//  ExpenseTracker
//
//  Created by migration from Android CategoryManagementScreen.kt
//

import SwiftUI

struct EditCategoryDialog: View {
    let category: Category?
    let subcategory: SubCategory?
    let onDismiss: () -> Void
    let onConfirm: (String, String?, String?) -> Void
    let isDarkTheme: Bool

    @State private var editName = ""
    @State private var selectedIconName = "category"
    @State private var selectedColorHex = "#FF9500"

    private let availableIcons: [(String, String)] = [
        ("restaurant", "fork.knife"),
        ("home", "house.fill"),
        ("directions_car", "car.fill"),
        ("local_hospital", "cross.fill"),
        ("movie", "tv.fill"),
        ("school", "graduationcap.fill"),
        ("shopping_cart", "cart.fill"),
        ("pets", "pawprint.fill"),
        ("work", "briefcase.fill"),
        ("account_balance", "building.columns.fill"),
        ("favorite", "heart.fill"),
        ("category", "folder.fill"),
        ("sports", "sportscourt.fill"),
        ("music_note", "music.note"),
        ("flight", "airplane"),
        ("hotel", "bed.double.fill"),
        ("restaurant_menu", "menucard.fill"),
        ("local_gas_station", "fuelpump.fill"),
        ("phone", "phone.fill"),
        ("computer", "laptopcomputer"),
        ("book", "book.fill"),
        ("cake", "birthday.cake.fill"),
        ("coffee", "cup.and.saucer.fill"),
        ("directions_bus", "bus.fill"),
        ("directions_walk", "figure.walk"),
        ("eco", "leaf.fill"),
        ("fitness_center", "dumbbell.fill"),
        ("gavel", "hammer.fill"),
        ("healing", "bandage.fill"),
        ("kitchen", "frying.pan.fill"),
        ("local_laundry_service", "washer.fill"),
        ("local_pharmacy", "pills.fill"),
        ("local_pizza", "birthday.cake.fill"),
        ("local_shipping", "shippingbox.fill"),
        ("lunch_dining", "takeoutbag.and.cup.and.straw.fill"),
        ("monetization_on", "dollarsign.circle.fill"),
        ("palette", "paintpalette.fill"),
        ("park", "tree.fill"),
        ("pool", "figure.pool.swim"),
        ("psychology", "brain.head.profile"),
        ("receipt", "receipt.fill"),
        ("security", "lock.fill"),
        ("spa", "spa"),
        ("star", "star.fill"),
        ("theater_comedy", "theatermasks.fill"),
        ("toys", "teddybear.fill"),
        ("volunteer_activism", "hands.and.sparkles.fill"),
        ("water_drop", "drop.fill"),
        ("wifi", "wifi")
    ]

    private let availableColors = [
        "#FF9500", "#007AFF", "#34C759", "#FF2D92", "#9D73E3",
        "#5856D6", "#FF3B30", "#64D2FF", "#5AC8FA", "#FFD60A",
        "#30D158", "#3F51B5", "#FF6B35", "#4ECDC4", "#45B7D1",
        "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    nameSection

                    if category != nil {
                        iconSelectionSection
                        colorSelectionSection
                    }
                }
                .padding(24)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("cancel".localized, action: onDismiss),
                trailing: Button("save".localized) {
                    onConfirm(
                        editName,
                        category != nil ? selectedIconName : nil,
                        category != nil ? selectedColorHex : nil
                    )
                }
                .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
        .onAppear {
            setupInitialValues()
        }
    }

    private var title: String {
        if subcategory != nil {
            return "edit_subcategory".localized
        } else if category != nil {
            return "edit_category".localized
        } else {
            return "edit".localized
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("enter_name_hint".localized, text: $editName)
                .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
        }
    }

    private var iconSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("icon_selection".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableIcons, id: \.0) { iconData in
                        let (iconName, systemName) = iconData
                        let isSelected = selectedIconName == iconName

                        Button(action: { selectedIconName = iconName }) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? hexToColor(selectedColorHex).opacity(0.2) : ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                isSelected ? hexToColor(selectedColorHex) : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme),
                                                lineWidth: isSelected ? 2 : 1
                                            )
                                    )

                                Image(systemName: systemName)
                                    .foregroundColor(isSelected ? hexToColor(selectedColorHex) : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                                    .font(.system(size: 24))
                            }
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("color_selection".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableColors, id: \.self) { colorHex in
                        let isSelected = selectedColorHex == colorHex

                        Button(action: { selectedColorHex = colorHex }) {
                            ZStack {
                                Circle()
                                    .fill(hexToColor(colorHex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                isSelected ? Color.white : Color.clear,
                                                lineWidth: isSelected ? 3 : 1
                                            )
                                    )

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .bold))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private func setupInitialValues() {
        if let subcat = subcategory {
            editName = subcat.name
        } else if let cat = category {
            editName = cat.name
            selectedIconName = cat.iconName
            selectedColorHex = cat.colorHex
        }
    }

    private func hexToColor(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Preview
struct EditCategoryDialog_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategory = Category.getDefaultCategories()[0]

        EditCategoryDialog(
            category: sampleCategory,
            subcategory: nil,
            onDismiss: { },
            onConfirm: { _, _, _ in },
            isDarkTheme: true
        )
    }
}