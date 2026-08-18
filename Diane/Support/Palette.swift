import SwiftUI

struct Palette {
    let bg: Color
    let card: Color
    let ink: Color
    let muted: Color
    let faint: Color
    let line: Color
    let track: Color
    let accent: Color
    let accentGlow: Color
    let rec: Color
    let pause: Color

    static let light = Palette(
        bg: Color(hex: "F3EDE4"),
        card: Color(hex: "FBF7F1").opacity(0.82),
        ink: Color(hex: "2C2824"),
        muted: Color(hex: "8A8176"),
        faint: Color(hex: "C4BBB0"),
        line: Color(hex: "2C2824").opacity(0.1),
        track: Color(hex: "2C2824").opacity(0.08),
        accent: Color(hex: "C4A36A"),
        accentGlow: Color(hex: "C4A36A").opacity(0.32),
        rec: Color(hex: "D23B32"),
        pause: Color(hex: "E39B3A")
    )

    static let dark = Palette(
        bg: Color(hex: "161310"),
        card: Color(hex: "241E1A").opacity(0.82),
        ink: Color(hex: "F3ECE4"),
        muted: Color(hex: "A39A90"),
        faint: Color(hex: "6E675F"),
        line: Color(hex: "F3ECE4").opacity(0.1),
        track: Color(hex: "F3ECE4").opacity(0.1),
        accent: Color(hex: "D4B57A"),
        accentGlow: Color(hex: "D4B57A").opacity(0.24),
        rec: Color(hex: "D23B32"),
        pause: Color(hex: "E39B3A")
    )

    static func current(for scheme: ColorScheme) -> Palette {
        scheme == .dark ? .dark : .light
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: Palette = .light
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

enum Layout {
    static let screenInset: CGFloat = 22
    static let cardPadding: CGFloat = 18
    static let stackSpacing: CGFloat = 16
    static let cardRadius: CGFloat = 22
    static let controlRadius: CGFloat = 16
}

struct PaletteProvider<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .environment(\.palette, Palette.current(for: colorScheme))
    }
}

struct SanctuaryBackground: View {
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            palette.bg
            GeometryReader { geo in
                EllipticalGradient(
                    gradient: Gradient(colors: [palette.accentGlow, Color.clear]),
                    center: .center,
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.55
                )
                .frame(width: geo.size.width * 1.2, height: geo.size.height * 0.7)
                .position(x: geo.size.width * 0.5, y: geo.size.height * -0.06)
            }
        }
        .ignoresSafeArea()
    }
}

struct CardBackground: ViewModifier {
    @Environment(\.palette) private var palette
    var cornerRadius: CGFloat = Layout.cardRadius

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(palette.card)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(palette.line, lineWidth: 1)
            )
            .shadow(color: palette.ink.opacity(0.08), radius: 20, x: 0, y: 16)
    }
}

struct PillButtonStyle: ButtonStyle {
    @Environment(\.palette) private var palette
    var filled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .tracking(1.0)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: Layout.controlRadius, style: .continuous)
                    .fill(filled ? palette.ink : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.controlRadius, style: .continuous)
                    .strokeBorder(filled ? Color.clear : palette.line, lineWidth: 1)
            )
            .shadow(color: filled ? palette.ink.opacity(0.08) : .clear, radius: 20, x: 0, y: 16)
            .foregroundStyle(filled ? palette.bg : palette.ink)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct SanctuaryToggle: View {
    @Binding var isOn: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        Button {
            Haptics.light()
            isOn.toggle()
        } label: {
            Capsule()
                .fill(isOn ? palette.ink : palette.track)
                .frame(width: 48, height: 30)
                .overlay(
                    Circle()
                        .fill(palette.card)
                        .frame(width: 24, height: 24)
                        .padding(3)
                        .offset(x: isOn ? 18 : 0),
                    alignment: .leading
                )
                .animation(.easeOut(duration: 0.2), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat = Layout.cardRadius) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }

    func sanctuaryBackground() -> some View {
        background(SanctuaryBackground())
    }

    func kickerStyle() -> some View {
        modifier(KickerText())
    }

    func displayTitleStyle() -> some View {
        modifier(DisplayTitleText())
    }

    func bodyStyle(muted: Bool = false) -> some View {
        modifier(BodyText(muted: muted))
    }

    func readingStyle(muted: Bool = false) -> some View {
        modifier(ReadingText(muted: muted))
    }
}

private struct KickerText: ViewModifier {
    @Environment(\.palette) private var palette
    func body(content: Content) -> some View {
        content
            .font(.system(size: 10, weight: .semibold))
            .textCase(.uppercase)
            .tracking(2.2)
            .foregroundStyle(palette.muted)
    }
}

private struct DisplayTitleText: ViewModifier {
    @Environment(\.palette) private var palette
    func body(content: Content) -> some View {
        content
            .font(.system(size: 28, weight: .light))
            .tracking(-1.0)
            .foregroundStyle(palette.ink)
    }
}

private struct BodyText: ViewModifier {
    @Environment(\.palette) private var palette
    var muted: Bool = false
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(muted ? palette.muted : palette.ink)
    }
}

private struct ReadingText: ViewModifier {
    @Environment(\.palette) private var palette
    var muted: Bool = false
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .regular, design: .serif))
            .lineSpacing(6)
            .foregroundStyle(muted ? palette.muted : palette.ink)
    }
}

extension Color {
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
