import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var libraryStore: DocumentLibraryStore
    @EnvironmentObject private var progressStore: ReadingProgressStore
    @State private var importerPresented = false
    @State private var selectedDocument: LibraryDocument?
    @State private var errorMessage: String?

    private let importService = DocumentImportService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                content
            }
            .navigationTitle("NightPDF")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        importerPresented = true
                    } label: {
                        Label("Abrir PDF", systemImage: "doc.badge.plus")
                    }
                    .accessibilityLabel("Abrir PDF")
                }
            }
            .fileImporter(isPresented: $importerPresented, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
                handleImport(result)
            }
            .navigationDestination(item: $selectedDocument) { document in
                ReaderView(document: document)
                    .environmentObject(libraryStore)
                    .environmentObject(progressStore)
            }
            .alert("NightPDF", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if libraryStore.documents.isEmpty {
            VStack(spacing: 18) {
                Image(systemName: "moonphase.last.quarter")
                    .font(.system(size: 54, weight: .regular))
                    .foregroundStyle(.white)
                Text("Biblioteca vacia")
                    .font(.title2.weight(.semibold))
                Button {
                    importerPresented = true
                } label: {
                    Label("Abrir PDF", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .foregroundStyle(.white)
            .padding()
        } else {
            List {
                ForEach(libraryStore.documents) { document in
                    Button {
                        selectedDocument = document
                    } label: {
                        DocumentRow(document: document)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            libraryStore.remove(document)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let document = try importService.importPDF(from: url)
            libraryStore.add(document)
            selectedDocument = document
        } catch let error as AppError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

