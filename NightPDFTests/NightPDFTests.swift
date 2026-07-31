import XCTest
import UIKit
@testable import NightPDF

@MainActor
final class NightPDFTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "NightPDFTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testLibraryPersistenceRoundTrip() {
        let store = DocumentLibraryStore(userDefaults: defaults)
        let document = LibraryDocument(displayName: "Book.pdf", localFileName: "one.pdf", lastPageIndex: 4)

        store.add(document)

        let reloaded = DocumentLibraryStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.documents, [document])
        XCTAssertEqual(reloaded.lastOpenedDocumentID, document.id)
    }

    func testProgressUpdatesPage() {
        let store = DocumentLibraryStore(userDefaults: defaults)
        let document = LibraryDocument(displayName: "Book.pdf", localFileName: "one.pdf")
        store.add(document)

        store.markOpened(document, pageIndex: 12)

        XCTAssertEqual(store.documents.first?.lastPageIndex, 12)
    }

    func testProgressStoresPreciseReadingLocation() {
        let store = DocumentLibraryStore(userDefaults: defaults)
        let document = LibraryDocument(displayName: "Book.pdf", localFileName: "one.pdf")
        store.add(document)

        store.markOpened(document, pageIndex: 7, pagePointX: 14.5, pagePointY: 300.25, scaleFactor: 1.7)

        let saved = store.documents.first
        XCTAssertEqual(saved?.lastPageIndex, 7)
        XCTAssertEqual(saved?.lastPagePointX, 14.5)
        XCTAssertEqual(saved?.lastPagePointY, 300.25)
        XCTAssertEqual(saved?.lastScaleFactor, 1.7)
    }

    func testDuplicateIdentifiersAreReplaced() {
        let store = DocumentLibraryStore(userDefaults: defaults)
        let id = UUID()
        store.add(LibraryDocument(id: id, displayName: "Old.pdf", localFileName: "old.pdf"))
        store.add(LibraryDocument(id: id, displayName: "New.pdf", localFileName: "new.pdf"))

        XCTAssertEqual(store.documents.count, 1)
        XCTAssertEqual(store.documents.first?.displayName, "New.pdf")
    }

    func testDeletingDocumentUpdatesLibrary() {
        let store = DocumentLibraryStore(userDefaults: defaults)
        let first = LibraryDocument(displayName: "First.pdf", localFileName: "first.pdf")
        let second = LibraryDocument(displayName: "Second.pdf", localFileName: "second.pdf")
        store.add(first)
        store.add(second)

        store.remove(second)

        XCTAssertEqual(store.documents, [first])
        XCTAssertEqual(store.lastOpenedDocumentID, first.id)
    }

    func testAppearancePersistence() {
        let progress = ReadingProgressStore(userDefaults: defaults)
        progress.appearance = .softNight
        progress.softNightIntensity = 0.8
        progress.keepScreenAwake = true

        let reloaded = ReadingProgressStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.appearance, .softNight)
        XCTAssertEqual(reloaded.softNightIntensity, 0.8, accuracy: 0.001)
        XCTAssertTrue(reloaded.keepScreenAwake)
    }

    func testImportingPDFsWithSameDisplayNameCreatesUniqueLocalFiles() throws {
        let service = DocumentImportService()
        let firstURL = try makeTemporaryPDF(named: "Sample.pdf")
        let secondURL = try makeTemporaryPDF(named: "Sample.pdf")

        let first = try service.importPDF(from: firstURL)
        let second = try service.importPDF(from: secondURL)

        XCTAssertEqual(first.displayName, "Sample.pdf")
        XCTAssertEqual(second.displayName, "Sample.pdf")
        XCTAssertNotEqual(first.localFileName, second.localFileName)
    }

    private func makeTemporaryPDF(named fileName: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 200))
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            "NightPDF".draw(at: CGPoint(x: 24, y: 24), withAttributes: [
                .font: UIFont.systemFont(ofSize: 18)
            ])
        }
        return url
    }
}
