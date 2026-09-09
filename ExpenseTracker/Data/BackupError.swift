//
//  BackupError.swift
//  ExpenseTracker
//
//  Errors surfaced by the backup / restore flow.
//

import Foundation

enum BackupError: LocalizedError {
    /// The file is not a backup produced by this app.
    case notABackupFile

    /// The file was written by a newer app version whose schema we cannot read.
    case fileFromNewerVersion(fileVersion: Int, supportedVersion: Int)

    /// A timestamp did not match any shape the Android or iOS writer can produce.
    case malformedDate(field: String, value: String)

    /// An enum value in the file has no counterpart in this build.
    case unknownEnumValue(field: String, value: String)

    /// The system denied access to the URL handed back by the document picker.
    case fileAccessDenied

    var errorDescription: String? {
        switch self {
        case .notABackupFile:
            return "import_error_invalid_file".localized

        case .fileFromNewerVersion:
            return "import_error_newer_version".localized

        case .malformedDate(let field, let value):
            return "import_error_corrupt_data".localized + " (\(field): \(value))"

        case .unknownEnumValue(let field, let value):
            return "import_error_corrupt_data".localized + " (\(field): \(value))"

        case .fileAccessDenied:
            return "import_error_file_access".localized
        }
    }
}
