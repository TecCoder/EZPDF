import SwiftUI

struct AppearancePanel: View {
    @Binding var appearance: ReadingAppearance
    @Binding var intensity: Double
    @Binding var keepScreenAwake: Bool

    var body: some View {
        Menu {
            Picker("Modo", selection: $appearance) {
                ForEach(ReadingAppearance.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            if appearance == .softNight {
                Slider(value: $intensity, in: 0...1) {
                    Text("Intensidad")
                }
            }

            Toggle(isOn: $keepScreenAwake) {
                Label("Pantalla activa", systemImage: "sun.max")
            }
        } label: {
            Label(appearance.title, systemImage: iconName)
        }
        .accessibilityLabel("Modo de visualizacion")
    }

    private var iconName: String {
        switch appearance {
        case .original: return "circle.lefthalf.filled"
        case .night: return "moon.fill"
        case .softNight: return "moon.stars.fill"
        }
    }
}

