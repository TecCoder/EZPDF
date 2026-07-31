import PDFKit
import SwiftUI

struct PDFReadingLocation: Equatable {
    var pageIndex: Int
    var point: CGPoint
    var scaleFactor: CGFloat
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    let initialPageIndex: Int
    let initialPagePoint: CGPoint?
    let initialScaleFactor: CGFloat?
    @Binding var currentPageIndex: Int
    @Binding var readingLocation: PDFReadingLocation?
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
        restoreInitialLocation(in: pdfView)
        DispatchQueue.main.async {
            pdfViewReference = pdfView
            totalPages = document.pageCount
        }
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== document {
            pdfView.document = document
            restoreInitialLocation(in: pdfView)
        }
        context.coordinator.parent = self
        context.coordinator.configure(pdfView)
        DispatchQueue.main.async {
            pdfViewReference = pdfView
            totalPages = document.pageCount
        }
    }

    private func restoreInitialLocation(in pdfView: PDFView) {
        let targetIndex = readingLocation?.pageIndex ?? initialPageIndex
        let targetPoint = readingLocation?.point ?? initialPagePoint
        let targetScale = readingLocation?.scaleFactor ?? initialScaleFactor
        let boundedIndex = min(max(targetIndex, 0), max(document.pageCount - 1, 0))
        if let page = document.page(at: boundedIndex) {
            if let targetPoint {
                pdfView.go(to: PDFDestination(page: page, at: targetPoint))
            } else {
                pdfView.go(to: page)
            }
            if let targetScale {
                pdfView.scaleFactor = min(
                    max(targetScale, pdfView.minScaleFactor),
                    pdfView.maxScaleFactor
                )
            }
        }
    }

    final class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFKitView
        private weak var pdfView: PDFView?
        private var observer: NSObjectProtocol?
        private weak var observedScrollView: UIScrollView?
        private var contentOffsetObservation: NSKeyValueObservation?
        private var zoomScaleObservation: NSKeyValueObservation?

        init(_ parent: PDFKitView) {
            self.parent = parent
            super.init()
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
            contentOffsetObservation?.invalidate()
            zoomScaleObservation?.invalidate()
        }

        func configure(_ pdfView: PDFView) {
            self.pdfView = pdfView
            installScrollObservation(in: pdfView)
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
            updateReadingLocation(from: pdfView)
        }

        private func installScrollObservation(in view: UIView) {
            guard let scrollView = findScrollView(in: view), observedScrollView !== scrollView else {
                return
            }
            observedScrollView = scrollView
            contentOffsetObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
                guard let pdfView = self?.pdfView else { return }
                self?.updateReadingLocation(from: pdfView)
            }
            zoomScaleObservation = scrollView.observe(\.zoomScale, options: [.new]) { [weak self] _, _ in
                guard let pdfView = self?.pdfView else { return }
                self?.updateReadingLocation(from: pdfView)
            }
        }

        private func findScrollView(in view: UIView) -> UIScrollView? {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            for subview in view.subviews {
                if let scrollView = findScrollView(in: subview) {
                    return scrollView
                }
            }
            return nil
        }

        private func updateReadingLocation(from pdfView: PDFView) {
            guard let destination = pdfView.currentDestination,
                  let page = destination.page,
                  let document = pdfView.document else { return }
            parent.currentPageIndex = document.index(for: page)
            parent.readingLocation = PDFReadingLocation(
                pageIndex: document.index(for: page),
                point: destination.point,
                scaleFactor: pdfView.scaleFactor
            )
        }
    }
}
