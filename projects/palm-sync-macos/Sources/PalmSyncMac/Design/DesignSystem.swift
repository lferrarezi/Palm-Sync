import SwiftUI

enum PalmTheme {
    static let corner: CGFloat = 8
    static let compactCorner: CGFloat = 6
    static let contentWidth: CGFloat = 1040
    static let sidebarTint = Color(red: 0.18, green: 0.44, blue: 0.34)
    static let amber = Color(red: 0.92, green: 0.67, blue: 0.25)
    static let ink = Color(red: 0.14, green: 0.16, blue: 0.18)
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(red: 0.91, green: 0.95, blue: 0.94),
                    Color(red: 0.96, green: 0.93, blue: 0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TimelineView(.animation) { context in
                Canvas { graphics, size in
                    let seconds = context.date.timeIntervalSinceReferenceDate
                    let x = (sin(seconds / 7) + 1) * size.width * 0.25 + size.width * 0.2
                    let y = (cos(seconds / 9) + 1) * size.height * 0.18 + size.height * 0.16
                    var path = Path()
                    path.addEllipse(in: CGRect(x: x, y: y, width: size.width * 0.48, height: size.height * 0.54))
                    graphics.fill(path, with: .radialGradient(
                        Gradient(colors: [.green.opacity(0.16), .clear]),
                        center: CGPoint(x: x + 180, y: y + 120),
                        startRadius: 10,
                        endRadius: 420
                    ))
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
    }
}

struct SourceBadge: View {
    var source: SyncSource

    var body: some View {
        Label(source.name, systemImage: source.symbol)
            .font(.caption.weight(.medium))
            .foregroundStyle(source.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassSurface(interactive: false, tint: source.tint.opacity(0.12), cornerRadius: PalmTheme.compactCorner)
    }
}

struct StatusPill: View {
    var state: SyncState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.color)
                .frame(width: 7, height: 7)
            Text(state.label)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .glassSurface(interactive: false, tint: state.color.opacity(0.10), cornerRadius: PalmTheme.compactCorner)
    }
}

struct MetricTile: View {
    var title: String
    var value: String
    var symbol: String
    var tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .glassSurface(interactive: false, tint: tint.opacity(0.12), cornerRadius: PalmTheme.compactCorner)

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(minHeight: 74)
        .glassSurface(interactive: false)
    }
}

extension View {
    @ViewBuilder
    func glassSurface(
        interactive: Bool = false,
        tint: Color? = nil,
        cornerRadius: CGFloat = PalmTheme.corner
    ) -> some View {
        if #available(macOS 26.0, *) {
            let glass = interactive ? Glass.regular.tint(tint).interactive() : Glass.regular.tint(tint)
            self
                .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    func glassButtonStyle(prominent: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            self.buttonStyle(.bordered)
        }
    }
}

