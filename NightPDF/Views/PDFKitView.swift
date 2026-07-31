import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    let initialPageIndex: Int
    let initialPagePoint: CGPoint?
    let initialScaleFactor: CGFloat?
    @Binding var currentPageIndex: Int
    @Binding var totalPages: Int
    @Binding var pdfViewReference: PDFView?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .black
        pdfView.document = document
        pdfView.delegate = context.coordinator
        context.coordinator.configure(pdfView)
        restoreInitialPage(in: pdfView)
        DispatchQueue.main.async {
            pdfViewReference = pdfView
            totalPages = document.pageCount
        }
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== document {
            pdfView.document = document
            restoreInitialPage(in: pdfView)
        }
        context.coordinator.parent = self
        context.coordinator.configure(pdfView)
        DispatchQueue.main.async {
            pdfViewReference = pdfView
            totalPages = document.pageCount
        }
    }

    private func restoreInitialPage(in pdfView: PDFView) {
        let boundedIndex = min(max(initialPageIndex, 0), max(document.pageCount - 1, 0))
        if let page = document.page(at: boundedIndex) {
            if let initialPagePoint {
                pdfView.go(to: PDFDestination(page: page, at: initialPagePoint))
            } else {
                pdfView.go(to: page)
            }
            if let initialScaleFactor {
                pdfView.scaleFactor = min(
                    max(initialScaleFactor, pdfView.minScaleFactor),
                    pdfView.maxScaleFactor
                )
            }
        }
    }

    final class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFKitView
        private weak var pdfView: PDFView?
        private var observer: NSObjectProtocol?

        init(_ parent: PDFKitView) {
            self.parent = parent
            super.init()
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        func configure(_ pdfView: PDFView) {
            self.pdfView = pdfView
            if observer == nil {
                observer = NotificationCenter.default.addObserver(
                    forName: .PDFViewPageChanged,
                    object: pdfView,
                    queue: .main
                ) { [weak self, weak pdfView] _ in
                    self?.pageChanged(pdfView)
                }
            }
        }

        private func pageChanged(_ pdfView: PDFView?) {
            guard let pdfView, let page = pdfView.currentPage, let document = pdfView.document else { return }
            parent.currentPageIndex = document.index(for: page)
        }
    }
}
