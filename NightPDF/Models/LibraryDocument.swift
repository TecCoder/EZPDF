import Foundation

struct LibraryDocument: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var localFileName: String
    var lastPageIndex: Int
    var lastOpenedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        localFileName: String,
        lastPageIndex: Int = 0,
        lastOpenedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.localFileName = localFileName
        self.lastPageIndex = lastPageIndex
        self.lastOpenedAt = lastOpenedAt
    }
}

