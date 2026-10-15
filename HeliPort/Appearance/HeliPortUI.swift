import SwiftUI

enum HeliPortUI {
    enum Color {
        static let accent = SwiftUI.Color.accentColor
        static let secondaryText = SwiftUI.Color.secondary
        static let signalGreen = SwiftUI.Color(red: 0.1, green: 0.8, blue: 0.4)
        static let signalYellow = SwiftUI.Color(red: 1.0, green: 0.7, blue: 0.1)
        static let signalRed = SwiftUI.Color(red: 0.9, green: 0.2, blue: 0.2)

        static let glassBackground = SwiftUI.Color.primary.opacity(0.05)

        static let cardGradient = LinearGradient(
            colors: [SwiftUI.Color.accentColor.opacity(0.1), SwiftUI.Color.accentColor.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Spacing {
        static let tiny: CGFloat = 2
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let menuHorizontalPadding: CGFloat = 14
        static let menuVerticalPadding: CGFloat = 4
    }

    enum IconSize {
        static let tiny: CGFloat = 10
        static let small: CGFloat = 14
        static let medium: CGFloat = 18
        static let large: CGFloat = 24
    }

    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 12
        static let large: CGFloat = 18
        static let xLarge: CGFloat = 24
    }

    enum Dashboard {
        static let width: CGFloat = 300
        static let height: CGFloat = 230
        static let iconSize: CGFloat = 40
    }
}

struct ModernMenuStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, HeliPortUI.Spacing.menuHorizontalPadding)
            .padding(.vertical, HeliPortUI.Spacing.menuVerticalPadding)
            .contentShape(Rectangle())
    }
}

extension View {
    func modernMenuItem() -> some View {
        self.modifier(ModernMenuStyle())
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Liquid Glass
//
// macOS 26 introduces the Liquid Glass design language. These helpers use the
// native APIs when available and fall back to materials on earlier systems, so
// the app keeps its deployment target of macOS 13.

extension View {
    /// Renders a glass surface in `shape` on macOS 26+, or a material surface below it.
    @ViewBuilder
    func heliPortGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(SwiftUI.Color.primary.opacity(0.08), lineWidth: 0.5))
        }
    }

    /// Convenience wrapper around ``heliPortGlass(in:interactive:)`` for rounded cards.
    func heliPortGlassCard(cornerRadius: CGFloat = HeliPortUI.Radius.large,
                           interactive: Bool = false) -> some View {
        heliPortGlass(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                      interactive: interactive)
    }

    /// Primary action button: Liquid Glass on macOS 26+, bordered-prominent below it.
    @ViewBuilder
    func heliPortProminentButtonStyle() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }

    /// Secondary action button: Liquid Glass on macOS 26+, bordered below it.
    @ViewBuilder
    func heliPortButtonStyle() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }
}
