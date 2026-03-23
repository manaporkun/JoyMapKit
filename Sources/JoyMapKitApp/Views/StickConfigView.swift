import SwiftUI
import JoyMapKitCore

extension StickConfig.StickMode: CaseIterable {
    public static var allCases: [StickConfig.StickMode] {
        [.mouse, .scroll, .wasd, .arrows, .disabled]
    }
}

struct StickConfigView: View {
    let stickName: String
    @Binding var config: StickConfig

    var body: some View {
        GroupBox(label: Label(stickName, systemImage: "l.joystick")) {
            VStack(alignment: .leading, spacing: 12) {
                modePicker
                deadzoneSlider
                outerDeadzoneSlider

                if config.mode != .disabled {
                    sensitivitySlider
                }

                if config.mode == .scroll {
                    scrollSpeedSlider
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Subviews

    private var modePicker: some View {
        LabeledContent("Mode") {
            Picker("Mode", selection: $config.mode) {
                ForEach(StickConfig.StickMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var deadzoneSlider: some View {
        LabeledContent("Deadzone") {
            HStack {
                Slider(value: $config.deadzone, in: 0.0...0.5, step: 0.01)
                Text(String(format: "%.2f", config.deadzone))
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }

    private var outerDeadzoneSlider: some View {
        LabeledContent("Outer Deadzone") {
            HStack {
                Slider(value: $config.outerDeadzone, in: 0.5...1.0, step: 0.01)
                Text(String(format: "%.2f", config.outerDeadzone))
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }

    private var sensitivitySlider: some View {
        LabeledContent("Sensitivity") {
            HStack {
                Slider(value: $config.sensitivity, in: 0.1...5.0, step: 0.1)
                Text(String(format: "%.1f", config.sensitivity))
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }

    private var scrollSpeedSlider: some View {
        LabeledContent("Scroll Speed") {
            HStack {
                Slider(
                    value: Binding(
                        get: { config.scrollSpeed ?? 5.0 },
                        set: { config.scrollSpeed = $0 }
                    ),
                    in: 1.0...20.0,
                    step: 0.5
                )
                Text(String(format: "%.1f", config.scrollSpeed ?? 5.0))
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
}
