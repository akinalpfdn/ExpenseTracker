//
//  CurrencyTests.swift
//  ExpenseTrackerTests
//
//  The currency list, and the rate memory the form prefills from.
//

import XCTest
@testable import ExpenseTracker

final class CurrencyTests: XCTestCase {

    /// Identity is the symbol — that is what every expense stores — so two currencies
    /// sharing one would be indistinguishable once saved.
    func testSymbolsAreUnique() {
        let symbols = Currency.all.map(\.symbol)
        let duplicates = Dictionary(grouping: symbols, by: { $0 }).filter { $1.count > 1 }.keys
        XCTAssertTrue(duplicates.isEmpty, "Shared symbols: \(duplicates.sorted())")
    }

    func testCodesAreUnique() {
        let codes = Currency.all.map(\.code)
        XCTAssertEqual(Set(codes).count, codes.count)
    }

    /// The four the app shipped with must stay exactly as they were stored: `"₺"`,
    /// `"$"`, `"€"`, `"£"`. Renaming one would orphan every existing expense in it.
    func testTheOriginalFourKeepTheirSymbols() {
        XCTAssertEqual(Currency.common.map(\.symbol), ["₺", "$", "€", "£"])
        XCTAssertEqual(Currency.default.symbol, "₺")
    }

    func testCommonCurrenciesAreInTheFullList() {
        for currency in Currency.common {
            XCTAssertTrue(Currency.all.contains(currency), "\(currency.code) missing from the full list")
        }
    }

    func testNamesResolveForEveryCode() {
        for currency in Currency.all {
            XCTAssertNotEqual(currency.name, currency.code, "\(currency.code) has no localised name")
        }
    }

    /// An expense recorded in a symbol that later leaves the list must still display,
    /// so the lookup falls back rather than returning nil.
    func testLookupFallsBackForUnknownSymbols() {
        let unknown = Currency.from(symbol: "☃")
        XCTAssertEqual(unknown.symbol, "☃")
        XCTAssertEqual(Currency.from(symbol: "₺").code, "TRY")
    }

    // MARK: - Rate Memory

    private func makePreferences() -> PreferencesManager {
        let preferences = PreferencesManager()
        UserDefaults.standard.removeObject(forKey: "last_exchange_rates")
        return preferences
    }

    func testRememberedRateComesBackForTheSamePair() {
        let preferences = makePreferences()
        preferences.rememberExchangeRate(41.5, from: "$", to: "₺")

        XCTAssertEqual(preferences.lastExchangeRate(from: "$", to: "₺"), 41.5)
    }

    /// The default currency can change, and USD→TRY says nothing about USD→EUR.
    func testRatesAreKeyedByPairNotByCurrency() {
        let preferences = makePreferences()
        preferences.rememberExchangeRate(41.5, from: "$", to: "₺")

        XCTAssertNil(preferences.lastExchangeRate(from: "$", to: "€"))
        XCTAssertNil(preferences.lastExchangeRate(from: "₺", to: "$"))
    }

    func testNothingRememberedForZeroOrSameCurrency() {
        let preferences = makePreferences()
        preferences.rememberExchangeRate(0, from: "$", to: "₺")
        preferences.rememberExchangeRate(3, from: "₺", to: "₺")

        XCTAssertNil(preferences.lastExchangeRate(from: "$", to: "₺"))
        XCTAssertNil(preferences.lastExchangeRate(from: "₺", to: "₺"))
    }

    func testTheLatestRateWinsForAPair() {
        let preferences = makePreferences()
        preferences.rememberExchangeRate(40, from: "$", to: "₺")
        preferences.rememberExchangeRate(42, from: "$", to: "₺")

        XCTAssertEqual(preferences.lastExchangeRate(from: "$", to: "₺"), 42)
    }
}
