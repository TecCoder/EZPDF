import Foundation
import PDFKit

struct DocumentImportService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func importPDF(from sourceURL: URL) throws -> LibraryDocument {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw AppError.fileUnavailable
        }

        guard sourceURL.pathExtension.lowercased() == "pdf" else {
            throw AppError.invalidPDF
        }

        let directory = try Self.localPDFDirectory(fileManager: fileManager)
        let localFileName = "\(UUID().uuidString).pdf"
        let destinationURL = directory.appendingPathComponent(localFileName)

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw AppError.copyFailed(error.localizedDescription)
        }

        guard let pdfDocument = PDFDocument(url: destinationURL), pdfDocument.pageCount > 0 else {
            try? fileManager.removeItem(at: destinationURL)
            throw AppError.invalidPDF
        }

        if pdfDocument.isLocked {
            try? fileManager.removeItem(at: destinationURL)
            throw AppError.protectedPDF
        }

        return LibraryDocument(
            displayName: sourceURL.lastPathComponent,
            localFileName: localFileName,
            lastPageIndex: 0,
            lastOpenedAt: Date()
        )
    }

    static func localPDFDirectory(fileManager: FileManager = .default) throws -> URL {
        guard let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw AppError.storageUnavailable
        }
        let directory = supportDirectory.appendingPathComponent("PDFs", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}

