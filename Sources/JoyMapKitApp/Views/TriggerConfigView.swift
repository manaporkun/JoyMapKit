import SwiftUI
import JoyMapKitCore

extension TriggerConfig.TriggerMode: CaseIterable {
    public static var allCases: [TriggerConfig.TriggerMode] {
        [.digital, .analog, .mouseScroll, .disabled]
    }
}

struct TriggerConfigView: View {
    let triggerName: String
    @Binding var config: TriggerConfig

    var body: some View {
        GroupBox(label: Label(triggerName, systemImage: "hand.point.down")) {
            VStack(alignment: .leading, spacing: 12) {
                modePicker

                if config.mode == .digital {
                    thresholdSlider
                }

                actionDisplay
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Subviews

    private var modePicker: some View {
        LabeledContent("Mode") {
            Picker("Mode", selection: $config.mode) {
                ForEach(TriggerConfig.TriggerMode.allCases, id: \.self) { mode in
                    Text(displayName(for: mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var thresholdSlider: some View {
        LabeledContent("Threshold") {
            HStack {
                Slider(value: $config.threshold, in: 0.0...1.0, step: 0.05)
                Text(String(format: "%.2f", config.threshold))
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }

    private var actionDisplay: some View {
        LabeledContent("Action") {
            Text(actionLabel)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func displayName(for mode: TriggerConfig.TriggerMode) -> String {
        switch mode {
        case .digital:     return "Digital"
        case .analog:      return "Analog"
        case .mouseScroll: return "Mouse Scroll"
        case .disabled:    return "Disabled"
        }
    }

    private var actionLabel: String {
        guard let action = config.action else { return "None" }
        switch action {
        case .keyPress:       return "Key Press"
        case .mouseClick:     return "Mouse Click"
        case .mouseMove:      return "Mouse Move"
        case .scroll:         return "Scroll"
        case .macro:          return "Macro"
        case .shell:          return "Shell"
        case .profileSwitch:  return "Profile Switch"
        case .layerToggle:    return "Layer Toggle"
        case .none:           return "None"
        }
    }
}
