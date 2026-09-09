//
//  DataManagementSection.swift
//  ExpenseTracker
//
//  Created by migration from Android SettingsScreen.kt DataManagementSection
//

import SwiftUI
import UniformTypeIdentifiers

struct DataManagementSection: View {

    /// Where a finished export should go. Chosen before the file exists, applied once
    /// the view model reports it staged.
    enum ExportDestination {
        case share
        case files
    }

    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var planningViewModel: PlanningViewModel
    @StateObject private var viewModel = DataManagementViewModel()

    let isDarkTheme: Bool

    // Export flow
    @State private var exportDestination: ExportDestination = .share
    @State private var showingExportOptions = false
    @State private var showingShareSheet = false
    @State private var showingFileExporter = false
    @State private var exportDocument: BackupDocument?

    // Import flow
    @State private var showingFileImporter = false
    @State private var pendingImportURL: URL?
    @State private var pendingImportPreview: ExportData?
    @State private var showingImportConfirmation = false
    @State private var showingImportSuccess = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            exportButton
            importButton
            errorMessage
        }
        .onChange(of: viewModel.state) { newState in
            handleStateChange(newState)
        }
        .confirmationDialog(
            "export_data".localized,
            isPresented: $showingExportOptions,
            titleVisibility: .visible
        ) {
            Button("share".localized) { beginExport(destination: .share) }
            Button("save_to_files".localized) { beginExport(destination: .files) }
            Button("cancel".localized, role: .cancel) { }
        } message: {
            Text("choose_export_destination".localized)
        }
        .sheet(isPresented: $showingShareSheet) {
            if case .exportReady(let url) = viewModel.state {
                ShareSheet(items: [url]) {
                    showingShareSheet = false
                    viewModel.cleanupExportFile()
                }
            }
        }
        .fileExporter(
            isPresented: $showingFileExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: BackupFileManager.makeBackupFileName()
        ) { _ in
            exportDocument = nil
            viewModel.cleanupExportFile()
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("import_confirm_title".localized, isPresented: $showingImportConfirmation) {
            Button("cancel".localized, role: .cancel) { clearPendingImport() }
            Button("import_confirm_button".localized, role: .destructive) { confirmImport() }
        } message: {
            Text(importConfirmationMessage)
        }
        .alert("import_success_title".localized, isPresented: $showingImportSuccess) {
            Button("ok".localized) {
                showingImportSuccess = false
                viewModel.dismiss()
            }
        } message: {
            if case .importSuccess(let summary) = viewModel.state {
                Text(summary)
            }
        }
    }
}

// MARK: - Subviews

extension DataManagementSection {

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("backup_restore".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Text("backup_restore_description".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var exportButton: some View {
        Button(action: { showingExportOptions = true }) {
            HStack(spacing: 8) {
                if viewModel.state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textWhite))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .medium))
                }

                Text("export_data".localized)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(AppColors.textWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppColors.primaryOrange)
            .cornerRadius(16)
        }
        .disabled(viewModel.state.isLoading)
    }

    private var importButton: some View {
        Button(action: { showingFileImporter = true }) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 15, weight: .medium))

                Text("import_data".localized)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.primaryOrange, lineWidth: 1)
            )
        }
        .disabled(viewModel.state.isLoading)
    }

    @ViewBuilder
    private var errorMessage: some View {
        if case .error(let message) = viewModel.state {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Spells out what is in the file and what restoring it will cost, because the
    /// import replaces everything and there is no undo.
    private var importConfirmationMessage: String {
        guard let preview = pendingImportPreview else {
            return "import_confirm_message".localized
        }

        let contents = [
            "\("expenses".localized): \(preview.expenses.count)",
            "\("categories".localized): \(preview.categories.count)",
            "\("financial_planning".localized): \(preview.financialPlans.count)"
        ].joined(separator: "\n")

        return "import_confirm_message".localized + "\n\n" + contents
    }
}

// MARK: - Actions

extension DataManagementSection {

    private func beginExport(destination: ExportDestination) {
        exportDestination = destination
        viewModel.exportData()
    }

    private func handleStateChange(_ state: DataManagementState) {
        switch state {
        case .exportReady(let url):
            switch exportDestination {
            case .share:
                showingShareSheet = true
            case .files:
                // Read the staged file back rather than re-serialising: this is the
                // exact bytes the share path would have produced.
                if let json = try? String(contentsOf: url, encoding: .utf8) {
                    exportDocument = BackupDocument(json: json)
                    showingFileExporter = true
                }
            }

        case .importSuccess:
            showingImportSuccess = true

        default:
            break
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            pendingImportURL = url
            pendingImportPreview = viewModel.previewImportFile(at: url)

            // Only ask for confirmation if the file actually parsed; otherwise the
            // view model has already surfaced the error.
            if pendingImportPreview != nil {
                showingImportConfirmation = true
            }

        case .failure(let error):
            pendingImportURL = nil
            pendingImportPreview = nil
            print("File import selection failed: \(error)")
        }
    }

    private func confirmImport() {
        guard let url = pendingImportURL else { return }

        viewModel.importData(from: url, strategy: .replaceAll) {
            Task { @MainActor in
                await expenseViewModel.reloadFromStore()
                await planningViewModel.reloadFromStore()
            }
        }

        clearPendingImport()
    }

    private func clearPendingImport() {
        pendingImportURL = nil
        pendingImportPreview = nil
    }
}
