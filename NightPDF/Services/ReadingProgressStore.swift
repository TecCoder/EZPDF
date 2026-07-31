import Foundation

@MainActor
final class ReadingProgressStore: ObservableObject {
    @Published var appearance: ReadingAppearance {
        didSet { saveAppearance() }
    }
    @Published var softNightIntensity: Double {
        didSet { saveIntensity() }
    }
    @Published var keepScreenAwake: Bool {
        didSet { userDefaults.set(keepScreenAwake, forKey: keepAwakeKey) }
    }

    private let userDefaults: UserDefaults
    private let appearanceKey: String
    private let intensityKey: String
    private let keepAwakeKey: String

    init(
        userDefaults: UserDefaults = .standard,
        appearanceKey: String = "nightpdf.reading.appearance",
        intensityKey: String = "nightpdf.reading.softNightIntensity",
        keepAwakeKey: String = "nightpdf.reading.keepScreenAwake"
    ) {
        self.userDefaults = userDefaults
        self.appearanceKey = appearanceKey
        self.intensityKey = intensityKey
        self.keepAwakeKey = keepAwakeKey

        if let rawValue = userDefaults.string(forKey: appearanceKey),
           let savedAppearance = ReadingAppearance(rawValue: rawValue) {
            appearance = savedAppearance
        } else {
            appearance = .original
        }

        let savedIntensity = userDefaults.object(forKey: intensityKey) as? Double ?? 0.55
        softNightIntensity = min(max(savedIntensity, 0), 1)
        keepScreenAwake = userDefaults.bool(forKey: keepAwakeKey)
    }

    func pageIndex(for document: LibraryDocument) -> Int {
        max(0, document.lastPageIndex)
    }

    private func saveAppearance() {
        userDefaults.set(appearance.rawValue, forKey: appearanceKey)
    }

    private func saveIntensity() {
        userDefaults.set(min(max(softNightIntensity, 0), 1), forKey: intensityKey)
    }
}

