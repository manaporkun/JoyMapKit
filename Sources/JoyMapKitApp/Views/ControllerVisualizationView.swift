import SwiftUI
import JoyMapKitCore

/// Visual gamepad that highlights buttons, sticks, triggers, and d-pad in real-time.
struct ControllerVisualizationView: View {

    var inputStates: [String: Float]

    // Reference frame: everything is laid out in a 480x320 coordinate space
    private let refW: CGFloat = 480
    private let refH: CGFloat = 320

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / refW, geo.size.height / refH)
            ZStack {
                // Controller body (single unified shape)
                controllerBody

                // Triggers
                triggerBar("Left Trigger", flipped: false).offset(x: -108, y: -118)
                triggerBar("Right Trigger", flipped: true).offset(x: 108, y: -118)

                // Bumpers
                bumper("Left Shoulder").offset(x: -108, y: -95)
                bumper("Right Shoulder").offset(x: 108, y: -95)

                // Left stick (upper-left)
                analogStick(xAxis: "Left Thumbstick X Axis",
                            yAxis: "Left Thumbstick Y Axis",
                            button: "Left Thumbstick Button")
                    .offset(x: -90, y: -30)

                // D-pad (lower-left)
                dpadView.offset(x: -90, y: 48)

                // Face buttons (upper-right)
                faceButtons.offset(x: 100, y: -15)

                // Right stick (lower-right)
                analogStick(xAxis: "Right Thumbstick X Axis",
                            yAxis: "Right Thumbstick Y Axis",
                            button: "Right Thumbstick Button")
                    .offset(x: 45, y: 48)

                // Center buttons
                centerButton("Button Options", icon: "chevron.left.2")
                    .offset(x: -22, y: -50)
                guideButton.offset(x: 0, y: -30)
                centerButton("Button Menu", icon: "line.3.horizontal")
                    .offset(x: 22, y: -50)
            }
            .frame(width: refW, height: refH)
            .scaleEffect(scale)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(refW / refH, contentMode: .fit)
        .animation(.easeOut(duration: 0.08), value: stateHash)
    }

    // MARK: - Controller Body

    private var controllerBody: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2

            // Main body path — Xbox-style with integrated grips
            let body = Path { p in
                // Start at top-left of the main body
                p.move(to: CGPoint(x: cx - 150, y: cy - 75))

                // Top edge
                p.addQuadCurve(
                    to: CGPoint(x: cx + 150, y: cy - 75),
                    control: CGPoint(x: cx, y: cy - 85))

                // Right shoulder curve down to right grip
                p.addCurve(
                    to: CGPoint(x: cx + 170, y: cy + 10),
                    control1: CGPoint(x: cx + 185, y: cy - 70),
                    control2: CGPoint(x: cx + 190, y: cy - 20))

                // Right grip — extends down and curves back
                p.addCurve(
                    to: CGPoint(x: cx + 130, y: cy + 110),
                    control1: CGPoint(x: cx + 175, y: cy + 55),
                    control2: CGPoint(x: cx + 165, y: cy + 100))

                // Bottom of right grip rounds inward
                p.addCurve(
                    to: CGPoint(x: cx + 60, y: cy + 85),
                    control1: CGPoint(x: cx + 100, y: cy + 120),
                    control2: CGPoint(x: cx + 80, y: cy + 100))

                // Bottom center
                p.addQuadCurve(
                    to: CGPoint(x: cx - 60, y: cy + 85),
                    control: CGPoint(x: cx, y: cy + 70))

                // Bottom of left grip rounds inward
                p.addCurve(
                    to: CGPoint(x: cx - 130, y: cy + 110),
                    control1: CGPoint(x: cx - 80, y: cy + 100),
                    control2: CGPoint(x: cx - 100, y: cy + 120))

                // Left grip — curves back up
                p.addCurve(
                    to: CGPoint(x: cx - 170, y: cy + 10),
                    control1: CGPoint(x: cx - 165, y: cy + 100),
                    control2: CGPoint(x: cx - 175, y: cy + 55))

                // Left shoulder curve back to top
                p.addCurve(
                    to: CGPoint(x: cx - 150, y: cy - 75),
                    control1: CGPoint(x: cx - 190, y: cy - 20),
                    control2: CGPoint(x: cx - 185, y: cy - 70))

                p.closeSubpath()
            }

            // Shadow
            ctx.drawLayer { shadow in
                shadow.addFilter(.shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6))
                shadow.fill(body, with: .color(.clear))
            }

            // Body gradient
            let gradient = Gradient(colors: [
                Color(red: 0.22, green: 0.22, blue: 0.24),
                Color(red: 0.16, green: 0.16, blue: 0.18),
            ])
            ctx.fill(body, with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: cx, y: cy - 80),
                endPoint: CGPoint(x: cx, y: cy + 110)))

            // Inner highlight along top
            let highlight = Path { p in
                p.move(to: CGPoint(x: cx - 130, y: cy - 70))
                p.addQuadCurve(
                    to: CGPoint(x: cx + 130, y: cy - 70),
                    control: CGPoint(x: cx, y: cy - 80))
            }
            ctx.stroke(highlight, with: .color(.white.opacity(0.08)), lineWidth: 2)

            // Subtle border
            ctx.stroke(body, with: .color(.white.opacity(0.06)), lineWidth: 1)

            // Grip texture lines (subtle)
            for grip in [cx - 155, cx + 155] {
                for i in 0..<4 {
                    let y = cy + 30 + CGFloat(i) * 14
                    let line = Path { p in
                        p.move(to: CGPoint(x: grip - 12, y: y))
                        p.addLine(to: CGPoint(x: grip + 12, y: y))
                    }
                    ctx.stroke(line, with: .color(.white.opacity(0.04)), lineWidth: 1)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Face Buttons

    private var faceButtons: some View {
        let s: CGFloat = 26
        return ZStack {
            faceBtn("A", .green, "Button A").offset(y: s)
            faceBtn("B", .red, "Button B").offset(x: s)
            faceBtn("X", .blue, "Button X").offset(x: -s)
            faceBtn("Y", .yellow, "Button Y").offset(y: -s)
        }
    }

    private func faceBtn(_ label: String, _ color: Color, _ element: String) -> some View {
        let on = isPressed(element)
        return ZStack {
            Circle()
                .fill(on ? color : Color(white: 0.13))
                .frame(width: 28, height: 28)
            Circle()
                .strokeBorder(color.opacity(on ? 1 : 0.6), lineWidth: 2)
                .frame(width: 28, height: 28)
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(on ? .black.opacity(0.85) : color)
        }
        .shadow(color: on ? color.opacity(0.8) : .clear, radius: 12)
    }

    // MARK: - D-Pad

    private var dpadView: some View {
        let w: CGFloat = 20
        let h: CGFloat = 24
        return ZStack {
            // Center
            Circle()
                .fill(Color(white: 0.20))
                .frame(width: 12, height: 12)

            // Arms
            dpadArm("Direction Pad Up", width: w, height: h).offset(y: -(w / 2 + h / 2))
            dpadArm("Direction Pad Down", width: w, height: h).offset(y: w / 2 + h / 2)
            dpadArm("Direction Pad Left", width: h, height: w).offset(x: -(w / 2 + h / 2))
            dpadArm("Direction Pad Right", width: h, height: w).offset(x: w / 2 + h / 2)
        }
    }

    private func dpadArm(_ element: String, width: CGFloat, height: CGFloat) -> some View {
        let on = isPressed(element)
        return RoundedRectangle(cornerRadius: 3)
            .fill(on ? Color.orange : Color(white: 0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color.white.opacity(on ? 0.2 : 0.06), lineWidth: 1)
            )
            .frame(width: width, height: height)
            .shadow(color: on ? Color.orange.opacity(0.7) : .clear, radius: 10)
    }

    // MARK: - Analog Sticks

    private func analogStick(xAxis: String, yAxis: String, button: String) -> some View {
        let x = CGFloat(inputStates[xAxis] ?? 0)
        let y = CGFloat(inputStates[yAxis] ?? 0)
        let clicked = isPressed(button)
        let travel: CGFloat = 18

        return ZStack {
            // Base ring
            Circle()
                .fill(Color(white: 0.12))
                .frame(width: 56, height: 56)
            Circle()
                .strokeBorder(
                    clicked ? Color.blue : Color(white: 0.30),
                    lineWidth: 2
                )
                .frame(width: 56, height: 56)
                .shadow(color: clicked ? Color.blue.opacity(0.6) : .clear, radius: 10)

            // Thumbstick cap
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.38), Color(white: 0.25)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 14
                        )
                    )
                    .frame(width: 28, height: 28)
                Circle()
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 28, height: 28)
                // Grip texture
                Circle()
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    .frame(width: 18, height: 18)
            }
            .offset(x: x * travel, y: -y * travel)
        }
    }

    // MARK: - Bumpers

    private func bumper(_ element: String) -> some View {
        let on = isPressed(element)
        return RoundedRectangle(cornerRadius: 8)
            .fill(on ? Color.purple : Color(white: 0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(on ? 0.15 : 0.06), lineWidth: 1)
            )
            .frame(width: 80, height: 20)
            .shadow(color: on ? Color.purple.opacity(0.7) : .clear, radius: 10)
    }

    // MARK: - Triggers

    private func triggerBar(_ element: String, flipped: Bool) -> some View {
        let value = CGFloat(inputStates[element] ?? 0)
        let w: CGFloat = 65
        let h: CGFloat = 14
        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(white: 0.14))
                .frame(width: w, height: h)

            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [.cyan.opacity(0.7), .blue],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(width: max(0, w * value), height: h)
                .shadow(color: value > 0.1 ? Color.cyan.opacity(0.4) : .clear, radius: 6)

            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                .frame(width: w, height: h)
        }
        .frame(width: w, height: h, alignment: .leading)
    }

    // MARK: - Center Buttons

    private func centerButton(_ element: String, icon: String) -> some View {
        let on = isPressed(element)
        return ZStack {
            Circle()
                .fill(on ? Color(white: 0.45) : Color(white: 0.20))
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            Image(systemName: icon)
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(on ? .black : Color(white: 0.50))
        }
        .shadow(color: on ? Color.white.opacity(0.3) : .clear, radius: 5)
    }

    private var guideButton: some View {
        let on = isPressed("Button Home")
        return ZStack {
            Circle()
                .fill(on ? Color.white.opacity(0.3) : Color(white: 0.18))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
            Image(systemName: "xbox.logo")
                .font(.system(size: 9))
                .foregroundColor(on ? .white : Color(white: 0.40))
        }
    }

    // MARK: - Helpers

    private func isPressed(_ element: String) -> Bool {
        (inputStates[element] ?? 0) > 0.1
    }

    private var stateHash: Int {
        var h = Hasher()
        for (k, v) in inputStates.sorted(by: { $0.key < $1.key }) {
            h.combine(k)
            h.combine(Int(v * 100))
        }
        return h.finalize()
    }
}
