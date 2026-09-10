//
//  CurrencyPickerSheet.swift
//  ExpenseTracker
//
//  One picker for every place a currency is chosen: the add-expense form, Settings,
//  and the welcome flow. Four buttons in a row worked for four currencies; with
//  forty, this is a searchable list with the original four pinned on top.
//

import SwiftUI

struct CurrencyPickerSheet: View {
    @Binding var selection: String
    let isDarkTheme: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationView {
            List {
                if query.isEmpty {
                    Section("currency_common".localized) {
                        ForEach(Currency.common) { row($0) }
                    }
                }

                Section(query.isEmpty ? "currency_all".localized : "") {
                    ForEach(matches) { row($0) }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "currency_search".localized)
            .navigationTitle("currency".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("done".localized) { dismiss() }
                }
            }
        }
        .preferredColorScheme(isDarkTheme ? .dark : .light)
    }

    /// Everything but the pinned four, by name, filtered by name, code or symbol.
    private var matches: [Currency] {
        let pool = query.isEmpty
            ? Currency.all.filter { !Currency.common.contains($0) }
            : Currency.all

        let sorted = pool.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        guard !query.isEmpty else { return sorted }

        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.code.localizedCaseInsensitiveContains(query)
                || $0.symbol.localizedCaseInsensitiveContains(query)
        }
    }

    private func row(_ currency: Currency) -> some View {
        Button {
            selection = currency.symbol
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Text(currency.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(minWidth: 44, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.name)
                        .font(.system(size: 16))
                    Text(currency.code)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if currency.symbol == selection {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.primaryOrange)
                }
            }
            .contentShape(Rectangle())
        }
        .foregroundColor(.primary)
    }
}
