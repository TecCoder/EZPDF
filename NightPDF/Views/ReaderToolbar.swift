import SwiftUI

struct ReaderToolbar: View {
    let title: String
    @Binding var searchText: String
    @Binding var showSearch: Bool
    let onBack: () -> Void
    let onSearch: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Label("Volver", systemImage: "chevron.left")
            }
            .labelStyle(.iconOnly)
            .accessibilityLabel("Volver")

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Button {
                showSearch = true
            } label: {
                Label("Buscar", systemImage: "magnifyingglass")
            }
            .labelStyle(.iconOnly)
            .accessibilityLabel("Buscar en el PDF")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.black.opacity(0.86))
    }
}

