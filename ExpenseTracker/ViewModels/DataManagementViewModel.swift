//
//  DataManagementViewModel.swift
//  ExpenseTracker
//
//  Created by migration from Android DataManagementViewModel.kt
//

import Foundation
import SwiftUI

enum DataManagementState: Equatable {
    case idle
    case loading

    /// A backup file has been staged and is ready to hand to the share sheet or the
    /// file exporter. The URL points into the temporary directory.
    case exportReady(url: URL)

    case importSuccess(summary: String)
    case error(message: String)

    static func == (lhs: DataManagementState, rhs: DataManagementState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.exportReady(let l), .exportReady(let r)):
            return l == r
        case (.importSuccess(let l), .importSuccess(let r)):
            return l == r
        case (.error(let l), .error(let r)):
            return l == r
        default:
            return false
        }
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

@MainActor
class DataManagementViewModel: ObservableObject {

    @Published private(set) var state: DataManagementState = .idle

    private let exportManager: ExportManager
    private let importManager: ImportManager

    /// Staged export file awaiting cleanup once the share / save sheet closes.
    private var stagedExportURL: URL?

    init(exportManager: ExportManager = ExportManager(),
         importManager: ImportManager = ImportManager()) {
        self.exportManager = exportManager
        self.importManager = importManager
    }

    // MARK: - Export

    func exportData() {
        state = .loading

        Task {
            do {
                let json = try await exportManager.exportAllData()
                let url = try BackupFileManager.stageForExport(json: json)

                stagedExportURL = url
                state = .exportReady(url: url)
            } catch {
                state = .error(message: error.localizedDescription)
            }
        }
    }

    /// Called once the share sheet or file exporter has finished with the staged file.
    func cleanupExportFile() {
        if let url = stagedExportURL {
            BackupFileManager.discardStagedFile(at: url)
            stagedExportURL = nil
        }
        state = .idle
    }

    // MARK: - Import

    /// Reads and validates a picked file without writing to the database, so the
    /// confirmation dialog can tell the user what the file actually contains.
    func previewImportFile(at url: URL) -> ExportData? {
        do {
            let json = try BackupFileManager.readImportFile(at: url)
            return try importManager.validateImportFile(json: json)
        } catch {
            state = .error(message: error.localizedDescription)
            return nil
        }
    }

    func importData(from url: URL, strategy: ImportStrategy, onComplete: @escaping () -> Void) {
        state = .loading

        Task {
            do {
                let json = try BackupFileManager.readImportFile(at: url)
                let summary = try await importManager.importData(json: json, strategy: strategy)

                state = .importSuccess(summary: Self.describe(summary))
                onComplete()
            } catch {
                state = .error(message: error.localizedDescription)
            }
        }
    }

    // MARK: - State

    func dismiss() {
        state = .idle
    }

    private static func describe(_ summary: ImportSummary) -> String {
        return [
            "\("categories".localized): \(summary.categoriesImported)",
            "\("sub_categories".localized): \(summary.subCategoriesImported)",
            "\("expenses".localized): \(summary.expensesImported)",
            "\("financial_planning".localized): \(summary.financialPlansImported)"
        ].joined(separator: "\n")
    }
}
