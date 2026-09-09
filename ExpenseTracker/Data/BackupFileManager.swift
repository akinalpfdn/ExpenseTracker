//
//  BackupFileManager.swift
//  ExpenseTracker
//
//  Created by migration from Android FileManager.kt
//
//  Handles the parts of backup / restore that touch the file system. On iOS this is
//  the fiddly half: files chosen through the document picker live outside our sandbox
//  and are only readable inside a security-scoped access block.
//

import Foundation

struct BackupFileManager {

    /// Directory we stage export files in before handing them to the share sheet or
    /// the file exporter. Cleared explicitly once the sheet is dismissed.
    private static var stagingDirectory: URL {
        return FileManager.default.temporaryDirectory
    }

    // MARK: - Naming

    /// `penko-backup-2026-09-09-1432.json` — sortable, and obvious in a Files listing.
    static func makeBackupFileName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return "penko-backup-\(formatter.string(from: Date())).json"
    }

    // MARK: - Writing

    /// Stages the JSON in the temporary directory and returns its URL.
    static func stageForExport(json: String) throws -> URL {
        let url = stagingDirectory.appendingPathComponent(makeBackupFileName())

        // Overwrite any leftover file with the same name from an aborted attempt.
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        try json.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// Removes a staged export file. Failure here is not worth surfacing — the
    /// temporary directory is reclaimed by the system regardless.
    static func discardStagedFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Reading

    /// Reads a file chosen through `.fileImporter`.
    ///
    /// The picker returns a URL outside our sandbox. Reading it without opening a
    /// security-scoped access block fails — and on some paths it fails *silently*,
    /// handing back empty data rather than an error, so the guard below is load-bearing.
    static func readImportFile(at url: URL) throws -> String {
        let needsScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw BackupError.fileAccessDenied
        }

        let data = try Data(contentsOf: url)

        guard let contents = String(data: data, encoding: .utf8), !contents.isEmpty else {
            throw BackupError.notABackupFile
        }

        return contents
    }

    // MARK: - App Version

    static func currentAppVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version ?? "1.0"
    }
}
