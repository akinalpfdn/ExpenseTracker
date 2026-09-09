//
//  ImportManager.swift
//  ExpenseTracker
//
//  Created by migration from Android ImportManager.kt
//

import Foundation

enum ImportStrategy {
    /// Wipe everything, then load the file. What the UI offers.
    case replaceAll

    /// Keep existing rows, overwriting only those the file also contains.
    case merge
}

struct ImportSummary {
    let categoriesImported: Int
    let subCategoriesImported: Int
    let expensesImported: Int
    let financialPlansImported: Int
    let planBreakdownsImported: Int
    let strategy: ImportStrategy
}

class ImportManager {
    private let dataAccess: BackupDataAccess

    init(dataAccess: BackupDataAccess = BackupDataAccess()) {
        self.dataAccess = dataAccess
    }

    // MARK: - Validation

    /// Parses and version-checks a file without touching the database. Used to show
    /// the user what they are about to restore before they commit to it.
    func validateImportFile(json: String) throws -> ExportData {
        let exportData: ExportData

        do {
            exportData = try JSONDecoder().decode(ExportData.self, from: Data(json.utf8))
        } catch {
            throw BackupError.notABackupFile
        }

        guard exportData.exportVersion >= 1 else {
            throw BackupError.notABackupFile
        }

        guard exportData.databaseVersion <= BackupSchema.databaseVersion else {
            throw BackupError.fileFromNewerVersion(
                fileVersion: exportData.databaseVersion,
                supportedVersion: BackupSchema.databaseVersion
            )
        }

        return exportData
    }

    // MARK: - Import

    func importData(json: String, strategy: ImportStrategy) async throws -> ImportSummary {
        let exportData = try validateImportFile(json: json)

        // Decode every row before writing anything. A malformed date halfway through
        // the file should fail the import outright, not after the store has been wiped.
        let categories = exportData.categories.map { $0.toEntity() }
        let subCategories = exportData.subCategories.map { $0.toEntity() }
        let expenses = try exportData.expenses.map { try $0.toEntity() }
        let plans = try exportData.financialPlans.map { try $0.toEntity() }
        let breakdowns = exportData.planMonthlyBreakdowns.map { $0.toEntity() }

        try await dataAccess.restore(
            categories: categories,
            subCategories: subCategories,
            expenses: expenses,
            plans: plans,
            breakdowns: breakdowns,
            strategy: strategy
        )

        return ImportSummary(
            categoriesImported: categories.count,
            subCategoriesImported: subCategories.count,
            expensesImported: expenses.count,
            financialPlansImported: plans.count,
            planBreakdownsImported: breakdowns.count,
            strategy: strategy
        )
    }
}
