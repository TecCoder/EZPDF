import SwiftUI

@main
struct NightPDFApp: App {
    @StateObject private var libraryStore = DocumentLibraryStore()
    @StateObject private var progressStore = ReadingProgressStore()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(libraryStore)
                .environmentObject(progressStore)
                .preferredColorScheme(.dark)
        }
    }
}

