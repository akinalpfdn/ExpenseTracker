//
//  LocalizationTests.swift
//  ExpenseTrackerTests
//
//  `NSLocalizedString` returns the key itself when no translation exists, so a missing
//  entry does not crash or warn — it just renders `clear` or `done` on screen, in every
//  language. These tests catch that.
//

import XCTest
@testable import ExpenseTracker

final class LocalizationTests: XCTestCase {

    /// Keys that were live in the UI but defined in none of the .strings files until
    /// Phase 002. Pinned here so they cannot silently go missing again.
    private let previouslyMissingKeys = [
        // Date range picker
        "start_date", "select_start_date", "select_end_date",
        "quick_select", "today", "yesterday",
        "this_week", "last_week", "this_month", "last_month",
        "apply", "clear", "done",

        // Shared labels
        "calendar", "currency", "recurrence", "optional", "no_description"
    ]

    func testPreviouslyMissingKeysNowResolve() {
        for key in previouslyMissingKeys {
            let translated = key.localized

            XCTAssertNotEqual(
                translated, key,
                "\"\(key)\" is undefined — the raw key will be shown to users"
            )
            XCTAssertFalse(
                translated.isEmpty,
                "\"\(key)\" resolves to an empty string"
            )
        }
    }

    /// A spot check on keys the backup UI depends on, added in Phase 001.
    func testBackupKeysResolve() {
        let backupKeys = [
            "backup_restore", "backup_restore_description",
            "export_data", "import_data",
            "share", "save_to_files", "choose_export_destination",
            "import_confirm_title", "import_confirm_button", "import_confirm_message",
            "import_success_title",
            "import_error_invalid_file", "import_error_newer_version",
            "import_error_corrupt_data", "import_error_file_access"
        ]

        for key in backupKeys {
            XCTAssertNotEqual(key.localized, key, "\"\(key)\" is undefined")
        }
    }

    /// Every language ships the same key set. A key present in English but absent in,
    /// say, Polish falls back to English rather than failing, so this is easy to miss.
    func testAllLanguagesDefineTheSameKeys() throws {
        let languages = ["en", "tr", "de", "es", "fr", "it", "pl", "pt-PT", "ru"]

        var keysByLanguage: [String: Set<String>] = [:]

        for language in languages {
            guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
                  let bundle = Bundle(path: path),
                  let stringsPath = bundle.path(forResource: "Localizable", ofType: "strings"),
                  let contents = NSDictionary(contentsOfFile: stringsPath) as? [String: String] else {
                return XCTFail("Could not load \(language).lproj")
            }
            keysByLanguage[language] = Set(contents.keys)
        }

        guard let englishKeys = keysByLanguage["en"] else {
            return XCTFail("English strings missing")
        }

        for (language, keys) in keysByLanguage where language != "en" {
            let missing = englishKeys.subtracting(keys)
            let extra = keys.subtracting(englishKeys)

            XCTAssertTrue(
                missing.isEmpty,
                "\(language) is missing: \(missing.sorted().joined(separator: ", "))"
            )
            XCTAssertTrue(
                extra.isEmpty,
                "\(language) has keys English does not: \(extra.sorted().joined(separator: ", "))"
            )
        }
    }
}
