import PDFKit
import UIKit

final class PDFNightModeRenderer {
    private weak var filteredView: UIView?
    private var overlayView: UIView?

    func apply(appearance: ReadingAppearance, intensity: Double, to pdfView: PDFView) {
        let targetView = pdfView.documentView ?? pdfView
        if filteredView !== targetView {
            clear()
            filteredView = targetView
        }

        targetView.layer.masksToBounds = true
        overlayView?.removeFromSuperview()
        overlayView = nil

        switch appearance {
        case .original:
            targetView.layer.compositingFilter = nil
            targetView.layer.filters = nil
            targetView.backgroundColor = .systemBackground
        case .night:
            targetView.layer.compositingFilter = "CIColorInvert"
            targetView.backgroundColor = .black
        case .softNight:
            targetView.layer.compositingFilter = "CIColorInvert"
            targetView.backgroundColor = .black
            let alpha = CGFloat(min(max(intensity, 0), 1)) * 0.45
            let overlay = UIView(frame: targetView.bounds)
            overlay.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            overlay.isUserInteractionEnabled = false
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            targetView.addSubview(overlay)
            overlayView = overlay
        }
    }

    func clear() {
        filteredView?.layer.compositingFilter = nil
        filteredView?.layer.filters = nil
        overlayView?.removeFromSuperview()
        overlayView = nil
    }
}

