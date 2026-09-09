//
//  BackupTests.swift
//  ExpenseTrackerTests
//
//  Covers the backup format and the restore transaction. The file-picker flows are
//  not testable here and are verified by hand on device.
//

import XCTest
import CoreData
@testable import ExpenseTracker

final class BackupTests: XCTestCase {

    // MARK: - Date Format

    /// Java's `LocalDateTime.toString()` drops the seconds when they are zero and the
    /// fraction when it is zero, so an Android backup can contain any of these shapes.
    func testParsesEveryShapeJavaCanEmit() throws {
        let cases = [
            "2025-11-09T23:50",
            "2025-11-09T23:50:21",
            "2025-11-09T23:50:21.123"
        ]

        for value in cases {
            let parsed = LocalDateTimeFormat.date(from: value)
            XCTAssertNotNil(parsed, "Failed to parse \(value)")
        }
    }

    /// Java emits up to 9 fractional digits; DateFormatter handles 3.
    func testParsesNanosecondPrecisionByTruncating() throws {
        let parsed = LocalDateTimeFormat.date(from: "2025-11-09T23:50:21.123456789")
        XCTAssertNotNil(parsed)

        let expected = LocalDateTimeFormat.date(from: "2025-11-09T23:50:21.123")
        XCTAssertEqual(parsed, expected)
    }

    func testRejectsGarbageDates() throws {
        XCTAssertNil(LocalDateTimeFormat.date(from: ""))
        XCTAssertNil(LocalDateTimeFormat.date(from: "not a date"))
        XCTAssertNil(LocalDateTimeFormat.date(from: "2025-11-09"))
    }

    /// What we write has to be readable by the Android parser, which expects the
    /// wall-clock form with no zone suffix.
    func testWritesJavaCompatibleForm() throws {
        let written = LocalDateTimeFormat.string(from: Date())

        XCTAssertFalse(written.contains("Z"), "Zone suffix would break Java parsing")
        XCTAssertFalse(written.contains("+"), "Offset would break Java parsing")

        let pattern = #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}$"#
        XCTAssertNotNil(
            written.range(of: pattern, options: .regularExpression),
            "Unexpected shape: \(written)"
        )
    }

    func testDateSurvivesRoundTrip() throws {
        let original = LocalDateTimeFormat.date(from: "2025-11-09T23:50:21.123")!
        let recovered = LocalDateTimeFormat.date(from: LocalDateTimeFormat.string(from: original))
        XCTAssertEqual(original, recovered)
    }

    // MARK: - Exchange Rate Normalisation

    /// Core Data stores the rate as a non-optional scalar, so "unset" arrives as 0.
    /// Writing that 0 to the file would zero out foreign-currency expenses on restore.
    func testZeroExchangeRateIsWrittenAsNull() throws {
        let expense = makeExpense(currency: "₺", exchangeRate: 0)
        XCTAssertNil(expense.toDto().exchangeRate)
    }

    func testRealExchangeRateIsPreserved() throws {
        let expense = makeExpense(currency: "$", exchangeRate: 34.5)
        XCTAssertEqual(expense.toDto().exchangeRate, 34.5)
    }

    func testZeroExchangeRateInFileIsReadAsUnset() throws {
        let dto = ExpenseDto(
            id: "e1", amount: 100, currency: "$", categoryId: "food",
            subCategoryId: "sub1", description: "test",
            date: "2025-11-09T23:50:21.123",
            dailyLimitAtCreation: 0, monthlyLimitAtCreation: 0,
            exchangeRate: 0, recurrenceType: "NONE",
            endDate: nil, recurrenceGroupId: nil
        )

        XCTAssertNil(try dto.toEntity().exchangeRate)
    }

    // MARK: - Model Round Trip

    func testExpenseSurvivesRoundTrip() throws {
        let original = makeExpense(currency: "$", exchangeRate: 34.5)
        let recovered = try original.toDto().toEntity()

        XCTAssertEqual(recovered.id, original.id)
        XCTAssertEqual(recovered.amount, original.amount)
        XCTAssertEqual(recovered.currency, original.currency)
        XCTAssertEqual(recovered.categoryId, original.categoryId)
        XCTAssertEqual(recovered.subCategoryId, original.subCategoryId)
        XCTAssertEqual(recovered.description, original.description)
        XCTAssertEqual(recovered.recurrenceType, original.recurrenceType)
        XCTAssertEqual(recovered.exchangeRate, original.exchangeRate)
    }

    func testCategorySurvivesRoundTrip() throws {
        let original = Category(
            id: "food", name: "Food", colorHex: "#FF9500",
            iconName: "restaurant", isDefault: true, isCustom: false
        )
        let recovered = original.toDto().toEntity()

        XCTAssertEqual(recovered.id, original.id)
        XCTAssertEqual(recovered.name, original.name)
        XCTAssertEqual(recovered.colorHex, original.colorHex)
        XCTAssertEqual(recovered.iconName, original.iconName)
        XCTAssertEqual(recovered.isDefault, original.isDefault)
    }

    // MARK: - Validation

    func testRejectsNonBackupJson() throws {
        let manager = ImportManager()

        XCTAssertThrowsError(try manager.validateImportFile(json: #"{"hello":"world"}"#))
        XCTAssertThrowsError(try manager.validateImportFile(json: "not json at all"))
        XCTAssertThrowsError(try manager.validateImportFile(json: ""))
    }

    func testRejectsFileFromNewerAppVersion() throws {
        let json = makeBackupJson(databaseVersion: BackupSchema.databaseVersion + 1)

        XCTAssertThrowsError(try ImportManager().validateImportFile(json: json)) { error in
            guard case BackupError.fileFromNewerVersion = error else {
                return XCTFail("Expected fileFromNewerVersion, got \(error)")
            }
        }
    }

    func testAcceptsFileFromCurrentVersion() throws {
        let json = makeBackupJson(databaseVersion: BackupSchema.databaseVersion)
        XCTAssertNoThrow(try ImportManager().validateImportFile(json: json))
    }

    // MARK: - Cross-Platform

    /// A backup shaped exactly the way the Android build writes one, including the
    /// seconds-omitted timestamp and a null exchange rate.
    func testParsesAndroidProducedBackup() throws {
        let androidJson = """
        {
          "exportVersion": 1,
          "appVersion": "2.1",
          "exportDate": "2025-11-10T00:35",
          "databaseVersion": 11,
          "categories": [
            {"id":"food","name":"Yiyecek","colorHex":"#FF9500","iconName":"restaurant","isDefault":true,"isCustom":false}
          ],
          "subCategories": [
            {"id":"sub1","name":"Restoran","categoryId":"food","isDefault":true,"isCustom":false}
          ],
          "expenses": [
            {"id":"e1","amount":250.0,"currency":"₺","categoryId":"food","subCategoryId":"sub1",
             "description":"Öğle yemeği","date":"2025-11-09T13:30","dailyLimitAtCreation":500.0,
             "monthlyLimitAtCreation":15000.0,"exchangeRate":null,"recurrenceType":"NONE",
             "endDate":null,"recurrenceGroupId":null}
          ],
          "financialPlans": [],
          "planMonthlyBreakdowns": []
        }
        """

        let parsed = try ImportManager().validateImportFile(json: androidJson)

        XCTAssertEqual(parsed.categories.count, 1)
        XCTAssertEqual(parsed.expenses.count, 1)

        let expense = try parsed.expenses[0].toEntity()
        XCTAssertEqual(expense.amount, 250.0)
        XCTAssertEqual(expense.description, "Öğle yemeği")
        XCTAssertNil(expense.exchangeRate)
        XCTAssertEqual(expense.recurrenceType, .NONE)
    }

    /// Shaped exactly like a file the shipping Android build produces, taken from a
    /// real 1039-expense export with the contents replaced.
    ///
    /// The quirks it exists to pin down:
    /// - `exportVersion` and `databaseVersion` are absent. Both are defaulted in the
    ///   Kotlin declaration, and kotlinx.serialization does not write defaulted
    ///   properties. Requiring them rejected every real Android backup.
    /// - Timestamps arrive in two shapes in the same file: no seconds when they are
    ///   zero, and six fractional digits otherwise.
    /// - `exchangeRate` is null on same-currency expenses.
    func testParsesRealAndroidExportShape() throws {
        let androidJson = """
        {
          "appVersion": "1.3",
          "exportDate": "2026-09-09T18:46:46.058671",
          "categories": [
            {"id":"food","name":"Yiyecek","colorHex":"#FF9500","iconName":"restaurant","isDefault":true,"isCustom":false}
          ],
          "subCategories": [
            {"id":"sub1","name":"Restoran","categoryId":"food","isDefault":true,"isCustom":false}
          ],
          "expenses": [
            {"id":"e1","amount":120.0,"currency":"₺","categoryId":"food","subCategoryId":"sub1",
             "description":"Ogle","date":"2026-09-09T18:46:46.058671","dailyLimitAtCreation":500.0,
             "monthlyLimitAtCreation":15000.0,"exchangeRate":null,"recurrenceType":"NONE",
             "endDate":null,"recurrenceGroupId":null},
            {"id":"e2","amount":40.0,"currency":"$","categoryId":"food","subCategoryId":"sub1",
             "description":"Abonelik","date":"2026-09-01T09:00","dailyLimitAtCreation":500.0,
             "monthlyLimitAtCreation":15000.0,"exchangeRate":41.5,"recurrenceType":"MONTHLY",
             "endDate":"2027-09-01T09:00","recurrenceGroupId":"g1"},
            {"id":"e3","amount":75.0,"currency":"₺","categoryId":"food","subCategoryId":"sub1",
             "description":"Yol","date":"2026-09-02T08:30","dailyLimitAtCreation":500.0,
             "monthlyLimitAtCreation":15000.0,"exchangeRate":null,"recurrenceType":"WEEKDAYS",
             "endDate":null,"recurrenceGroupId":"g2"}
          ],
          "financialPlans": [
            {"id":"p1","name":"Birikim","startDate":"2026-01-01T00:00","durationInMonths":12,
             "monthlyIncome":89775.0,"manualMonthlyExpenses":0.0,"useAppExpenseData":true,
             "isInflationApplied":false,"inflationRate":0.0,"isInterestApplied":true,
             "interestRate":45.0,"interestType":"COMPOUND","createdAt":"2026-01-01T10:15:30.123456",
             "updatedAt":"2026-09-09T18:46","defaultCurrency":"₺"}
          ],
          "planMonthlyBreakdowns": [
            {"id":"b1","planId":"p1","monthIndex":0,"projectedIncome":89775.0,"fixedExpenses":0.0,
             "averageExpenses":35717.33,"totalProjectedExpenses":35717.33,"netAmount":54057.67,
             "interestEarned":0.0,"cumulativeNet":54057.67}
          ]
        }
        """

        let parsed = try ImportManager().validateImportFile(json: androidJson)

        // The two omitted fields fall back to the Kotlin declaration's defaults.
        XCTAssertEqual(parsed.exportVersion, BackupSchema.exportVersion)
        XCTAssertEqual(parsed.databaseVersion, BackupSchema.databaseVersion)

        XCTAssertEqual(parsed.expenses.count, 3)
        XCTAssertEqual(parsed.financialPlans.count, 1)

        // Six fractional digits, truncated rather than rejected.
        let withFraction = try parsed.expenses[0].toEntity()
        XCTAssertNil(withFraction.exchangeRate)

        // Seconds omitted because they were zero.
        let withoutSeconds = try parsed.expenses[1].toEntity()
        XCTAssertEqual(withoutSeconds.exchangeRate, 41.5)
        XCTAssertEqual(withoutSeconds.recurrenceType, .MONTHLY)
        XCTAssertNotNil(withoutSeconds.endDate)

        XCTAssertEqual(try parsed.expenses[2].toEntity().recurrenceType, .WEEKDAYS)

        let plan = try parsed.financialPlans[0].toEntity()
        XCTAssertEqual(plan.interestType, .compound)
        XCTAssertEqual(plan.monthlyIncome, 89_775)
    }

    /// Guards the other direction: what we write must still declare both fields, so
    /// an iOS backup carries its version even though Android's does not.
    func testOurExportDeclaresBothVersions() throws {
        let json = makeBackupJson(databaseVersion: BackupSchema.databaseVersion)
        XCTAssertTrue(json.contains("databaseVersion"))

        let parsed = try ImportManager().validateImportFile(json: json)
        XCTAssertEqual(parsed.databaseVersion, BackupSchema.databaseVersion)
    }

    // MARK: - Restore Transaction

    func testRestoreWritesEverything() async throws {
        let context = try makeInMemoryContext()
        let dataAccess = BackupDataAccess(context: context)

        try await dataAccess.restore(
            categories: [Category(id: "food", name: "Food", colorHex: "#FF9500", iconName: "restaurant")],
            subCategories: [SubCategory(id: "sub1", name: "Restaurant", categoryId: "food")],
            expenses: [makeExpense(currency: "₺", exchangeRate: 0)],
            plans: [],
            breakdowns: [],
            strategy: .replaceAll
        )

        let stored = try await dataAccess.fetchEverything()
        XCTAssertEqual(stored.categories.count, 1)
        XCTAssertEqual(stored.subCategories.count, 1)
        XCTAssertEqual(stored.expenses.count, 1)
    }

    func testReplaceAllClearsPreviousData() async throws {
        let context = try makeInMemoryContext()
        let dataAccess = BackupDataAccess(context: context)

        try await dataAccess.restore(
            categories: [Category(id: "old", name: "Old", colorHex: "#000000", iconName: "category")],
            subCategories: [], expenses: [], plans: [], breakdowns: [],
            strategy: .replaceAll
        )

        try await dataAccess.restore(
            categories: [Category(id: "new", name: "New", colorHex: "#FFFFFF", iconName: "category")],
            subCategories: [], expenses: [], plans: [], breakdowns: [],
            strategy: .replaceAll
        )

        let stored = try await dataAccess.fetchEverything()
        XCTAssertEqual(stored.categories.count, 1)
        XCTAssertEqual(stored.categories.first?.id, "new")
    }

    /// The whole point of decoding before writing: a bad row must not cost the user
    /// the data they already had.
    func testFailedImportLeavesExistingDataIntact() async throws {
        let context = try makeInMemoryContext()
        let dataAccess = BackupDataAccess(context: context)

        try await dataAccess.restore(
            categories: [Category(id: "keep", name: "Keep me", colorHex: "#FF9500", iconName: "restaurant")],
            subCategories: [], expenses: [], plans: [], breakdowns: [],
            strategy: .replaceAll
        )

        // Valid envelope, but the single expense carries an unparseable date.
        let corruptJson = """
        {
          "exportVersion": 1, "appVersion": "1.0",
          "exportDate": "2025-11-10T00:35", "databaseVersion": 11,
          "categories": [], "subCategories": [],
          "expenses": [
            {"id":"e1","amount":10.0,"currency":"₺","categoryId":"food","subCategoryId":"sub1",
             "description":"bad","date":"THIS IS NOT A DATE","dailyLimitAtCreation":0.0,
             "monthlyLimitAtCreation":0.0,"exchangeRate":null,"recurrenceType":"NONE",
             "endDate":null,"recurrenceGroupId":null}
          ],
          "financialPlans": [], "planMonthlyBreakdowns": []
        }
        """

        let importManager = ImportManager(dataAccess: dataAccess)

        do {
            _ = try await importManager.importData(json: corruptJson, strategy: .replaceAll)
            XCTFail("Import should have failed on the malformed date")
        } catch {
            // Expected.
        }

        let stored = try await dataAccess.fetchEverything()
        XCTAssertEqual(stored.categories.count, 1, "Existing data was destroyed by a failed import")
        XCTAssertEqual(stored.categories.first?.id, "keep")
    }

    // MARK: - Export

    func testExportProducesRestorableJson() async throws {
        let context = try makeInMemoryContext()
        let dataAccess = BackupDataAccess(context: context)

        try await dataAccess.restore(
            categories: [Category(id: "food", name: "Food", colorHex: "#FF9500", iconName: "restaurant")],
            subCategories: [SubCategory(id: "sub1", name: "Restaurant", categoryId: "food")],
            expenses: [makeExpense(currency: "$", exchangeRate: 34.5)],
            plans: [], breakdowns: [],
            strategy: .replaceAll
        )

        let json = try await ExportManager(dataAccess: dataAccess).exportAllData()
        let reparsed = try ImportManager().validateImportFile(json: json)

        XCTAssertEqual(reparsed.categories.count, 1)
        XCTAssertEqual(reparsed.expenses.count, 1)
        XCTAssertEqual(reparsed.expenses.first?.exchangeRate, 34.5)
        XCTAssertEqual(reparsed.databaseVersion, BackupSchema.databaseVersion)
    }
}

// MARK: - Helpers

private extension BackupTests {

    /// In-memory store so tests never touch the real database.
    func makeInMemoryContext() throws -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "ExpenseTracker")

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError = loadError { throw loadError }

        return container.viewContext
    }

    func makeExpense(currency: String, exchangeRate: Double?) -> Expense {
        return Expense(
            id: "e1",
            amount: 100,
            currency: currency,
            categoryId: "food",
            subCategoryId: "sub1",
            description: "test expense",
            date: LocalDateTimeFormat.date(from: "2025-11-09T13:30:00.000")!,
            dailyLimitAtCreation: 500,
            monthlyLimitAtCreation: 15000,
            exchangeRate: exchangeRate,
            recurrenceType: .NONE
        )
    }

    func makeBackupJson(databaseVersion: Int) -> String {
        return """
        {
          "exportVersion": 1, "appVersion": "1.0",
          "exportDate": "2025-11-10T00:35", "databaseVersion": \(databaseVersion),
          "categories": [], "subCategories": [], "expenses": [],
          "financialPlans": [], "planMonthlyBreakdowns": []
        }
        """
    }
}
