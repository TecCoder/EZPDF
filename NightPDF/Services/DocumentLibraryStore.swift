import Foundation

@MainActor
final class DocumentLibraryStore: ObservableObject {
    @Published private(set) var documents: [LibraryDocument] = []
    @Published var lastOpenedDocumentID: UUID?

    private let userDefaults: UserDefaults
    private let documentsKey: String
    private let lastDocumentKey: String

    init(
        userDefaults: UserDefaults = .standard,
        documentsKey: String = "nightpdf.library.documents",
        lastDocumentKey: String = "nightpdf.library.lastDocumentID"
    ) {
        self.userDefaults = userDefaults
        self.documentsKey = documentsKey
        self.lastDocumentKey = lastDocumentKey
        load()
    }

    func add(_ document: LibraryDocument) {
        documents.removeAll { $0.id == document.id }
        documents.insert(document, at: 0)
        lastOpenedDocumentID = document.id
        save()
    }

    func update(_ document: LibraryDocument) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index] = document
        documents.sort { $0.lastOpenedAt > $1.lastOpenedAt }
        lastOpenedDocumentID = document.id
        save()
    }

    func remove(_ document: LibraryDocument, fileManager: FileManager = .default) {
        documents.removeAll { $0.id == document.id }
        if lastOpenedDocumentID == document.id {
            lastOpenedDocumentID = documents.first?.id
        }
        if let url = try? DocumentImportService.localPDFDirectory(fileManager: fileManager).appendingPathComponent(document.localFileName) {
            try? fileManager.removeItem(at: url)
        }
        save()
    }

    func documentURL(for document: LibraryDocument, fileManager: FileManager = .default) throws -> URL {
        let directory = try DocumentImportService.localPDFDirectory(fileManager: fileManager)
        let url = directory.appendingPathComponent(document.localFileName)
        guard fileManager.fileExists(atPath: url.path) else { throw AppError.documentMissing }
        return url
    }

    func markOpened(_ document: LibraryDocument, pageIndex: Int? = nil) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index].lastOpenedAt = Date()
        if let pageIndex {
            documents[index].lastPageIndex = max(0, pageIndex)
        }
        let updated = documents[index]
        documents.sort { $0.lastOpenedAt > $1.lastOpenedAt }
        lastOpenedDocumentID = updated.id
        save()
    }

    func load() {
        if let data = userDefaults.data(forKey: documentsKey),
           let decoded = try? JSONDecoder().decode([LibraryDocument].self, from: data) {
            documents = decoded.sorted { $0.lastOpenedAt > $1.lastOpenedAt }
        }
        if let idString = userDefaults.string(forKey: lastDocumentKey) {
            lastOpenedDocumentID = UUID(uuidString: idString)
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(documents) {
            userDefaults.set(data, forKey: documentsKey)
        }
        userDefaults.set(lastOpenedDocumentID?.uuidString, forKey: lastDocumentKey)
    }
}

