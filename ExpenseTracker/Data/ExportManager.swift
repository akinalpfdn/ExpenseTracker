//
//  ExportManager.swift
//  ExpenseTracker
//
//  Created by migration from Android ExportManager.kt
//

import Foundation

class ExportManager {
    private let dataAccess: BackupDataAccess

    init(dataAccess: BackupDataAccess = BackupDataAccess()) {
        self.dataAccess = dataAccess
    }

    /// Serialises the entire database to the shared backup JSON format.
    func exportAllData() async throws -> String {
        let stored = try await dataAccess.fetchEverything()

        let exportData = ExportData(
            exportVersion: BackupSchema.exportVersion,
            appVersion: BackupFileManager.currentAppVersion(),
            exportDate: LocalDateTimeFormat.string(from: Date()),
            databaseVersion: BackupSchema.databaseVersion,
            categories: stored.categories.map { $0.toDto() },
            subCategories: stored.subCategories.map { $0.toDto() },
            expenses: stored.expenses.map { $0.toDto() },
            financialPlans: stored.plans.map { $0.toDto() },
            planMonthlyBreakdowns: stored.breakdowns.map { $0.toDto() }
        )

        let encoder = JSONEncoder()
        // Pretty-printed to match the Android output, and so the file is legible if a
        // user opens it to check what they are about to restore.
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        let data = try encoder.encode(exportData)

        guard let json = String(data: data, encoding: .utf8) else {
            throw BackupError.notABackupFile
        }

        return json
    }
}
