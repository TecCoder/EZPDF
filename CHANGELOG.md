# Changelog

## 0.1.0

- Created the native SwiftUI iPadOS project.
- Added PDF import into local Application Support storage.
- Added a local document library with progress persistence.
- Added PDFKit reader with continuous vertical scrolling, zoom, page tracking, search, and page jump.
- Added Original, Night, and Soft Night reading appearances.
- Changed night rendering to SwiftUI pixel inversion over the PDF view after device testing showed PDFKit layer filters were not reliable.
- Added restoration of exact reading destination and zoom when reopening a PDF.
- Added GitHub Actions CI and manual IPA/archive build workflows.
- Added Windows to iPad installation documentation.
