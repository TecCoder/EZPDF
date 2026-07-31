import SwiftUI

struct DocumentRow: View {
    let document: LibraryDocument

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.title2)
                .foregroundStyle(.cyan)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text("Pagina \(document.lastPageIndex + 1) - \(document.lastOpenedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

