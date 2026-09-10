//
//  Currency.swift
//  ExpenseTracker
//
//  The currencies the app offers, and the one rule that shapes the list.
//
//  Identity is the symbol. Every expense, the default-currency preference and the
//  backup file store `"₺"` rather than `"TRY"` — and so does the Android build — so
//  switching to ISO codes would break every existing row and cross-platform restore.
//  That means symbols have to be unique here: Canada is `CA$`, not `$`; Norway is
//  `NOK`, not the `kr` it shares with two neighbours.
//

import Foundation

struct Currency: Identifiable, Hashable {
    /// ISO 4217, used for the localised name and nothing else.
    let code: String

    /// What is stored, compared and shown. Unique across the list.
    let symbol: String

    var id: String { symbol }

    /// "Turkish Lira", "Türk Lirası", "Турецкая лира" — from the system, in the
    /// user's language, with no strings of ours to maintain.
    var name: String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    // MARK: - The List

    static let `default` = Currency(code: "TRY", symbol: "₺")

    /// The four the app shipped with. Pinned to the top of the picker.
    static let common: [Currency] = [
        Currency(code: "TRY", symbol: "₺"),
        Currency(code: "USD", symbol: "$"),
        Currency(code: "EUR", symbol: "€"),
        Currency(code: "GBP", symbol: "£")
    ]

    static let all: [Currency] = common + [
        Currency(code: "JPY", symbol: "¥"),
        Currency(code: "CNY", symbol: "CN¥"),
        Currency(code: "INR", symbol: "₹"),
        Currency(code: "RUB", symbol: "₽"),
        Currency(code: "PLN", symbol: "zł"),
        Currency(code: "CHF", symbol: "CHF"),
        Currency(code: "CAD", symbol: "CA$"),
        Currency(code: "AUD", symbol: "A$"),
        Currency(code: "NZD", symbol: "NZ$"),
        Currency(code: "SEK", symbol: "SEK"),
        Currency(code: "NOK", symbol: "NOK"),
        Currency(code: "DKK", symbol: "DKK"),
        Currency(code: "CZK", symbol: "Kč"),
        Currency(code: "HUF", symbol: "Ft"),
        Currency(code: "RON", symbol: "lei"),
        Currency(code: "BGN", symbol: "лв"),
        Currency(code: "UAH", symbol: "₴"),
        Currency(code: "ILS", symbol: "₪"),
        Currency(code: "AED", symbol: "AED"),
        Currency(code: "SAR", symbol: "SAR"),
        Currency(code: "QAR", symbol: "QAR"),
        Currency(code: "EGP", symbol: "E£"),
        Currency(code: "ZAR", symbol: "R"),
        Currency(code: "BRL", symbol: "R$"),
        Currency(code: "MXN", symbol: "MX$"),
        Currency(code: "ARS", symbol: "AR$"),
        Currency(code: "KRW", symbol: "₩"),
        Currency(code: "HKD", symbol: "HK$"),
        Currency(code: "SGD", symbol: "S$"),
        Currency(code: "TWD", symbol: "NT$"),
        Currency(code: "THB", symbol: "฿"),
        Currency(code: "VND", symbol: "₫"),
        Currency(code: "IDR", symbol: "Rp"),
        Currency(code: "MYR", symbol: "RM"),
        Currency(code: "PHP", symbol: "₱"),
        Currency(code: "KZT", symbol: "₸"),
        Currency(code: "AZN", symbol: "₼"),
        Currency(code: "GEL", symbol: "₾"),
        Currency(code: "NGN", symbol: "₦")
    ]

    // MARK: - Lookup

    /// The currency behind a stored symbol. Falls back to a bare entry rather than
    /// nil, so an expense recorded in a symbol we no longer list still displays.
    static func from(symbol: String) -> Currency {
        all.first { $0.symbol == symbol } ?? Currency(code: symbol, symbol: symbol)
    }
}
