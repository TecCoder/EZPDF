import PDFKit
import SwiftUI
import UIKit

struct ReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var libraryStore: DocumentLibraryStore
    @EnvironmentObject private var progressStore: ReadingProgressStore

    @State private var document: LibraryDocument
    @State private var pdfDocument: PDFDocument?
    @State private var errorMessage: String?
    @State private var controlsVisible = true
    @State private var currentPage = 0
    @State private var totalPages = 0
    @State private var jumpText = ""
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var searchResults: [PDFSelection] = []
    @State private var activeSearchIndex = 0
    @State private var pdfViewReference: PDFView?

    init(document: LibraryDocument) {
        _document = State(initialValue: document)
        _currentPage = State(initialValue: document.lastPageIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let pdfDocument {
                PDFKitView(
                    document: pdfDocument,
                    initialPageIndex: document.lastPageIndex,
                    appearance: progressStore.appearance,
                    intensity: progressStore.softNightIntensity,
                    currentPageIndex: $currentPage,
                    totalPages: $totalPages,
                    pdfViewReference: $pdfViewReference
                )
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        controlsVisible.toggle()
                    }
                }
            } else {
                ProgressView()
                    .tint(.white)
            }

            if controlsVisible {
                VStack(spacing: 0) {
                    ReaderToolbar(
                        title: document.displayName,
                        searchText: $searchText,
                        showSearch: $showSearch,
                        onBack: { dismiss() },
                        onSearch: runSearch
                    )
                    Spacer()
                    bottomBar
                }
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSearch) {
            searchSheet
                .presentationDetents([.height(170)])
        }
        .alert("NightPDF", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            loadDocument()
            UIApplication.shared.isIdleTimerDisabled = progressStore.keepScreenAwake
        }
        .onDisappear {
            libraryStore.markOpened(document, pageIndex: currentPage)
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: currentPage) { newValue in
            document.lastPageIndex = max(0, newValue)
            libraryStore.markOpened(document, pageIndex: newValue)
        }
        .onChange(of: progressStore.keepScreenAwake) { newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text("\(min(currentPage + 1, max(totalPages, 1))) / \(max(totalPages, 1))")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(minWidth: 76, alignment: .leading)

                TextField("Pagina", text: $jumpText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)

                Button {
                    jumpToPage()
                } label: {
                    Label("Ir", systemImage: "arrow.right.circle")
                }
                .labelStyle(.iconOnly)
                .accessibilityLabel("Ir a pagina")

                Spacer()

                AppearancePanel(
                    appearance: $progressStore.appearance,
                    intensity: $progressStore.softNightIntensity,
                    keepScreenAwake: $progressStore.keepScreenAwake
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.black.opacity(0.86))
        }
    }

    private var searchSheet: some View {
        VStack(spacing: 14) {
            HStack {
                TextField("Buscar", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(runSearch)
                Button {
                    runSearch()
                } label: {
                    Label("Buscar", systemImage: "magnifyingglass")
                }
            }

            HStack {
                Text("\(searchResults.count) resultados")
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    moveSearch(by: -1)
                } label: {
                    Label("Anterior", systemImage: "chevron.up")
                }
                .disabled(searchResults.isEmpty)
                Button {
                    moveSearch(by: 1)
                } label: {
                    Label("Siguiente", systemImage: "chevron.down")
                }
                .disabled(searchResults.isEmpty)
            }
        }
        .padding()
    }

    private func loadDocument() {
        do {
            let url = try libraryStore.documentURL(for: document)
            guard let loadedDocument = PDFDocument(url: url), loadedDocument.pageCount > 0 else {
                throw AppError.invalidPDF
            }
            if loadedDocument.isLocked {
                throw AppError.protectedPDF
            }
            pdfDocument = loadedDocument
            totalPages = loadedDocument.pageCount
            currentPage = min(document.lastPageIndex, max(loadedDocument.pageCount - 1, 0))
        } catch let error as AppError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func jumpToPage() {
        guard let pageNumber = Int(jumpText), let pdfView = pdfViewReference else { return }
        let pageIndex = min(max(pageNumber - 1, 0), max(totalPages - 1, 0))
        if let page = pdfDocument?.page(at: pageIndex) {
            pdfView.go(to: page)
        }
        jumpText = ""
    }

    private func runSearch() {
        guard let pdfDocument, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        searchResults = pdfDocument.findString(searchText, withOptions: .caseInsensitive)
        activeSearchIndex = 0
        goToActiveSearchResult()
    }

    private func moveSearch(by offset: Int) {
        guard !searchResults.isEmpty else { return }
        activeSearchIndex = (activeSearchIndex + offset + searchResults.count) % searchResults.count
        goToActiveSearchResult()
    }

    private func goToActiveSearchResult() {
        guard searchResults.indices.contains(activeSearchIndex), let pdfView = pdfViewReference else { return }
        let selection = searchResults[activeSearchIndex]
        pdfView.setCurrentSelection(selection, animate: true)
        pdfView.go(to: selection)
    }
}
