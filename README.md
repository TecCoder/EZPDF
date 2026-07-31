# NightPDF

NightPDF is a native iPadOS PDF reader focused on night reading. It imports PDFs from Files, stores local copies in the app container, remembers progress, and applies a visual-only night filter through PDFKit without modifying the original document.

## Requirements

- Xcode 16 or the stable Xcode version available on the GitHub Actions macOS runner.
- iPadOS 16.0 or later.
- No third-party dependencies.

## Architecture

- `Models`: Codable app models and reading appearance.
- `Services`: import, persistence, reading preferences, and PDF night rendering.
- `Views`: SwiftUI screens and the `PDFView` bridge.
- `NightPDFTests`: unit tests for persistence and library behavior.

The PDF is rendered with `PDFKit.PDFView` inside `UIViewRepresentable`. Night mode is applied to the PDF document view with Core Image layer filters, keeping SwiftUI controls outside the filter.

## Build Locally On macOS

```bash
xcodebuild \
  -project NightPDF.xcodeproj \
  -scheme NightPDF \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4)' \
  CODE_SIGNING_ALLOWED=NO \
  clean test
```

If that simulator is not installed, run:

```bash
xcrun simctl list devices available
```

Then replace the destination with an available iPad simulator.

## GitHub Actions

- `.github/workflows/ci.yml` builds and tests on every push and pull request.
- `.github/workflows/build-ipa.yml` runs manually and uploads build artifacts.

The manual workflow attempts to package an unsigned `NightPDF.ipa` and always uploads the `.xcarchive` when the archive step succeeds. Personal Apple credentials must never be committed or printed in logs.

## Install On iPad From Windows

See [docs/INSTALL_WINDOWS_IPAD.md](docs/INSTALL_WINDOWS_IPAD.md).

The free path is:

1. Build with GitHub Actions.
2. Download the artifact on Windows.
3. Sign and install with AltStore Classic or Sideloadly.

A free Apple Account signature normally expires after about 7 days and must be refreshed.

## Known Night Mode Limits

- The MVP uses full visual inversion, so photos and colored images may appear as negatives.
- `layer.compositingFilter` is intentionally isolated to the `PDFView.documentView`; if future iPadOS versions change PDFKit internals, this renderer is the single place to adapt.
- The soft night mode adds a dimming overlay after inversion. It is a comfort adjustment, not semantic recoloring.

