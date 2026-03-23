import SwiftUI
import JoyMapKitCore

/// Displays and allows editing of a single binding (input → action).
struct BindingRowView: View {
    @Binding var binding: BindingConfig
    @State private var showPressToAssign = false
    @State private var capturedElement: String?

    var body: some View {
        HStack(spacing: 12) {
            // Input
            VStack(alignment: .leading, spacing: 2) {
                Text("Input")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(inputDisplayName)
                        .font(.callout.monospaced())
                    Button {
                        showPressToAssign = true
                    } label: {
                        Image(systemName: "target")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Press to assign")
                }
            }
            .frame(minWidth: 160, alignment: .leading)

            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)

            // Action
            VStack(alignment: .leading, spacing: 2) {
                Text("Action")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(actionDisplayName)
                    .font(.callout)
            }
            .frame(minWidth: 160, alignment: .leading)

            Spacer()

            // Hold behavior
            if let hold = binding.holdBehavior {
                Text(holdDisplayName(hold))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1), in: Capsule())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showPressToAssign) {
            PressToAssignSheet(capturedElement: $capturedElement, isPresented: $showPressToAssign)
        }
        .onChange(of: capturedElement) { newValue in
            if let newValue {
                binding.input = .single(newValue)
                capturedElement = nil
            }
        }
    }

    private var inputDisplayName: String {
        switch binding.input {
        case .single(let name):
            return name
        case .chord(let elements):
            return elements.joined(separator: " + ")
        case .sequence(let elements, let timeout):
            return elements.joined(separator: " → ") + " (\(timeout)ms)"
        }
    }

    private var actionDisplayName: String {
        switch binding.action {
        case .keyPress(let action):
            var parts = [String]()
            for mod in action.modifiers {
                parts.append(mod.rawValue.capitalized)
            }
            parts.append(action.key ?? "Key \(action.keyCode)")
            return parts.joined(separator: "+")
        case .mouseClick(let action):
            return "Mouse \(action.button.rawValue.capitalized)"
        case .mouseMove:
            return "Mouse Move"
        case .scroll:
            return "Scroll"
        case .macro(let action):
            return "Macro: \(action.name ?? "\(action.steps.count) steps")"
        case .shell(let action):
            return "Shell: \(action.command)"
        case .profileSwitch(let name):
            return "Profile: \(name)"
        case .layerToggle(let name):
            return "Layer: \(name)"
        case .none:
            return "None"
        }
    }

    private func holdDisplayName(_ hold: HoldBehavior) -> String {
        switch hold {
        case .onPress: return "on press"
        case .onRelease: return "on release"
        case .whileHeld(let ms): return "repeat \(ms)ms"
        case .toggle: return "toggle"
        }
    }
}
