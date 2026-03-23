import SwiftUI
import JoyMapKitCore

struct AboutView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated logo
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
            }

            Text("JoyMapKit")
                .font(.title.bold())
                .padding(.top, 4)

            Text("v\(JoyMapKitVersion.current)")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Text("Gamepad-to-keyboard/mouse mapper for macOS")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            Spacer()

            Divider().opacity(0.5)

            HStack {
                Text("MIT License")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text("Built with Swift & GameController")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}
