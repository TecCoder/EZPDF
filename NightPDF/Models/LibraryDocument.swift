import Foundation

struct LibraryDocument: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var localFileName: String
    var lastPageIndex: Int
    var lastPagePointX: Double?
    var lastPagePointY: Double?
    var lastScaleFactor: Double?
    var lastOpenedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        localFileName: String,
        lastPageIndex: Int = 0,
        lastPagePointX: Double? = nil,
        lastPagePointY: Double? = nil,
        lastScaleFactor: Double? = nil,
        lastOpenedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.localFileName = localFileName
        self.lastPageIndex = lastPageIndex
        self.lastPagePointX = lastPagePointX
        self.lastPagePointY = lastPagePointY
        self.lastScaleFactor = lastScaleFactor
        self.lastOpenedAt = lastOpenedAt
    }
}
