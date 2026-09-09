//
//  BackupSharing.swift
//  ExpenseTracker
//
//  Plumbing for getting a staged backup file out of the app — either through the
//  share sheet or by saving it into Files.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Save to Files

/// Wraps an already-staged backup file for `.fileExporter`.
///
/// The JSON is produced before this type is created, so `init(configuration:)` is
/// never the path the app uses to build one — it exists only to satisfy `FileDocument`,
/// which requires a reading initialiser even for export-only documents.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let json: String

    init(json: String) {
        self.json = json
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let contents = String(data: data, encoding: .utf8) else {
            throw BackupError.notABackupFile
        }
        self.json = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: Data(json.utf8))
    }
}

// MARK: - Share Sheet

/// `UIActivityViewController` bridge.
///
/// `ShareLink` would cover the common case, but it has to be declared up front as a
/// view, whereas the export file only exists after the database has been serialised.
/// Presenting the activity controller ourselves keeps the flow "tap export, then
/// choose what to do with it".
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update — the item set is fixed for the lifetime of the sheet.
    }
}
