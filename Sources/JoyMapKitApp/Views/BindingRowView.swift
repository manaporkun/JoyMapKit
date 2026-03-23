import SwiftUI
import JoyMapKitCore

/// Common key codes for the key picker.
private struct KeyOption: Identifiable, Hashable {
    let id: String
    let label: String
    let keyCode: UInt16

    static let common: [KeyOption] = [
        KeyOption(id: "return", label: "Return", keyCode: 36),
        KeyOption(id: "escape", label: "Escape", keyCode: 53),
        KeyOption(id: "space", label: "Space", keyCode: 49),
        KeyOption(id: "tab", label: "Tab", keyCode: 48),
        KeyOption(id: "delete", label: "Delete", keyCode: 51),
        KeyOption(id: "up", label: "Up Arrow", keyCode: 126),
        KeyOption(id: "down", label: "Down Arrow", keyCode: 125),
        KeyOption(id: "left", label: "Left Arrow", keyCode: 123),
        KeyOption(id: "right", label: "Right Arrow", keyCode: 124),
        KeyOption(id: "a", label: "A", keyCode: 0),
        KeyOption(id: "b", label: "B", keyCode: 11),
        KeyOption(id: "c", label: "C", keyCode: 8),
        KeyOption(id: "d", label: "D", keyCode: 2),
        KeyOption(id: "e", label: "E", keyCode: 14),
        KeyOption(id: "f", label: "F", keyCode: 3),
        KeyOption(id: "g", label: "G", keyCode: 5),
        KeyOption(id: "h", label: "H", keyCode: 4),
        KeyOption(id: "i", label: "I", keyCode: 34),
        KeyOption(id: "j", label: "J", keyCode: 38),
        KeyOption(id: "k", label: "K", keyCode: 40),
        KeyOption(id: "l", label: "L", keyCode: 37),
        KeyOption(id: "m", label: "M", keyCode: 46),
        KeyOption(id: "n", label: "N", keyCode: 45),
        KeyOption(id: "o", label: "O", keyCode: 31),
        KeyOption(id: "p", label: "P", keyCode: 35),
        KeyOption(id: "q", label: "Q", keyCode: 12),
        KeyOption(id: "r", label: "R", keyCode: 15),
        KeyOption(id: "s", label: "S", keyCode: 1),
        KeyOption(id: "t", label: "T", keyCode: 17),
        KeyOption(id: "u", label: "U", keyCode: 32),
        KeyOption(id: "v", label: "V", keyCode: 9),
        KeyOption(id: "w", label: "W", keyCode: 13),
        KeyOption(id: "x", label: "X", keyCode: 7),
        KeyOption(id: "y", label: "Y", keyCode: 16),
        KeyOption(id: "z", label: "Z", keyCode: 6),
        KeyOption(id: "1", label: "1", keyCode: 18),
        KeyOption(id: "2", label: "2", keyCode: 19),
        KeyOption(id: "3", label: "3", keyCode: 20),
        KeyOption(id: "4", label: "4", keyCode: 21),
        KeyOption(id: "5", label: "5", keyCode: 23),
        KeyOption(id: "6", label: "6", keyCode: 22),
        KeyOption(id: "7", label: "7", keyCode: 26),
        KeyOption(id: "8", label: "8", keyCode: 28),
        KeyOption(id: "9", label: "9", keyCode: 25),
        KeyOption(id: "0", label: "0", keyCode: 29),
        KeyOption(id: "f1", label: "F1", keyCode: 122),
        KeyOption(id: "f2", label: "F2", keyCode: 120),
        KeyOption(id: "f3", label: "F3", keyCode: 99),
        KeyOption(id: "f4", label: "F4", keyCode: 118),
        KeyOption(id: "f5", label: "F5", keyCode: 96),
        KeyOption(id: "f6", label: "F6", keyCode: 97),
        KeyOption(id: "f7", label: "F7", keyCode: 98),
        KeyOption(id: "f8", label: "F8", keyCode: 100),
        KeyOption(id: "f9", label: "F9", keyCode: 101),
        KeyOption(id: "f10", label: "F10", keyCode: 109),
        KeyOption(id: "f11", label: "F11", keyCode: 103),
        KeyOption(id: "f12", label: "F12", keyCode: 111),
    ]
}

/// Displays and allows full editing of a single binding (input → action).
struct BindingRowView: View {
    @Binding var binding: BindingConfig
    @State private var showPressToAssign = false
    @State private var capturedElement: String?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Summary row (always visible)
            HStack(spacing: 12) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .frame(width: 12)
                }
                .buttonStyle(.borderless)

                // Input
                VStack(alignment: .leading, spacing: 2) {
                    Text("Input")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text(inputDisplayName)
                            .font(.callout.monospaced())
                        Button { showPressToAssign = true } label: {
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

                // Action summary
                VStack(alignment: .leading, spacing: 2) {
                    Text("Action")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(actionDisplayName)
                        .font(.callout)
                }
                .frame(minWidth: 160, alignment: .leading)

                Spacer()

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
            .contentShape(Rectangle())
            .onTapGesture { isExpanded.toggle() }

            // Expanded editor
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    actionEditor

                    Divider()

                    holdBehaviorEditor
                }
                .padding(.leading, 24)
                .padding(.vertical, 8)
            }
        }
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

    // MARK: - Action Editor

    private var actionEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Action")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            // Action type picker
            HStack {
                Text("Type:")
                    .frame(width: 70, alignment: .trailing)
                Picker("", selection: actionTypeBinding) {
                    Text("Key Press").tag("keyPress")
                    Text("Mouse Click").tag("mouseClick")
                    Text("Scroll").tag("scroll")
                    Text("None").tag("none")
                }
                .labelsHidden()
                .frame(width: 150)
            }

            // Type-specific fields
            switch binding.action {
            case .keyPress(let keyAction):
                keyPressEditor(keyAction)
            case .mouseClick(let clickAction):
                mouseClickEditor(clickAction)
            case .scroll(let scrollAction):
                scrollEditor(scrollAction)
            default:
                EmptyView()
            }
        }
    }

    private func keyPressEditor(_ action: ActionConfig.KeyPressAction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Key:")
                    .frame(width: 70, alignment: .trailing)
                Picker("", selection: keyCodeBinding) {
                    ForEach(KeyOption.common) { opt in
                        Text(opt.label).tag(opt.keyCode)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }

            HStack {
                Text("Modifiers:")
                    .frame(width: 70, alignment: .trailing)
                Toggle("Cmd", isOn: modifierBinding(.command))
                    .toggleStyle(.checkbox)
                Toggle("Ctrl", isOn: modifierBinding(.control))
                    .toggleStyle(.checkbox)
                Toggle("Opt", isOn: modifierBinding(.option))
                    .toggleStyle(.checkbox)
                Toggle("Shift", isOn: modifierBinding(.shift))
                    .toggleStyle(.checkbox)
            }
        }
    }

    private func mouseClickEditor(_ action: ActionConfig.MouseClickAction) -> some View {
        HStack {
            Text("Button:")
                .frame(width: 70, alignment: .trailing)
            Picker("", selection: mouseButtonBinding) {
                Text("Left").tag(ActionConfig.MouseClickAction.MouseButton.left)
                Text("Right").tag(ActionConfig.MouseClickAction.MouseButton.right)
                Text("Middle").tag(ActionConfig.MouseClickAction.MouseButton.middle)
            }
            .labelsHidden()
            .frame(width: 150)
        }
    }

    private func scrollEditor(_ action: ActionConfig.ScrollAction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Scroll X:")
                    .frame(width: 70, alignment: .trailing)
                TextField("dx", value: scrollDxBinding, format: .number)
                    .frame(width: 80)
            }
            HStack {
                Text("Scroll Y:")
                    .frame(width: 70, alignment: .trailing)
                TextField("dy", value: scrollDyBinding, format: .number)
                    .frame(width: 80)
            }
        }
    }

    // MARK: - Hold Behavior Editor

    private var holdBehaviorEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hold Behavior")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                Text("Mode:")
                    .frame(width: 70, alignment: .trailing)
                Picker("", selection: holdTypeBinding) {
                    Text("On Press").tag("onPress")
                    Text("On Release").tag("onRelease")
                    Text("Toggle").tag("toggle")
                    Text("While Held").tag("whileHeld")
                }
                .labelsHidden()
                .frame(width: 150)
            }

            if case .whileHeld(let ms) = binding.holdBehavior {
                HStack {
                    Text("Repeat:")
                        .frame(width: 70, alignment: .trailing)
                    TextField("ms", value: whileHeldMsBinding, format: .number)
                        .frame(width: 80)
                    Text("ms")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Bindings

    private var actionTypeBinding: Binding<String> {
        Binding(
            get: {
                switch binding.action {
                case .keyPress: return "keyPress"
                case .mouseClick: return "mouseClick"
                case .scroll: return "scroll"
                default: return "none"
                }
            },
            set: { newType in
                switch newType {
                case "keyPress":
                    binding.action = .keyPress(.init(keyCode: 36, key: "Return"))
                case "mouseClick":
                    binding.action = .mouseClick(.init(button: .left))
                case "scroll":
                    binding.action = .scroll(.init(dx: 0, dy: 5))
                default:
                    binding.action = .none
                }
            }
        )
    }

    private var keyCodeBinding: Binding<UInt16> {
        Binding(
            get: {
                if case .keyPress(let a) = binding.action { return a.keyCode }
                return 36
            },
            set: { newCode in
                let label = KeyOption.common.first { $0.keyCode == newCode }?.label ?? "Key \(newCode)"
                if case .keyPress(var a) = binding.action {
                    a.keyCode = newCode
                    a.key = label
                    binding.action = .keyPress(a)
                }
            }
        )
    }

    private func modifierBinding(_ modifier: ActionConfig.KeyPressAction.Modifier) -> Binding<Bool> {
        Binding(
            get: {
                if case .keyPress(let a) = binding.action {
                    return a.modifiers.contains(modifier)
                }
                return false
            },
            set: { isOn in
                if case .keyPress(var a) = binding.action {
                    if isOn {
                        if !a.modifiers.contains(modifier) { a.modifiers.append(modifier) }
                    } else {
                        a.modifiers.removeAll { $0 == modifier }
                    }
                    // Update display key
                    let keyLabel = KeyOption.common.first { $0.keyCode == a.keyCode }?.label ?? "Key \(a.keyCode)"
                    let modLabels = a.modifiers.map { $0.rawValue.capitalized }
                    a.key = (modLabels + [keyLabel]).joined(separator: "+")
                    binding.action = .keyPress(a)
                }
            }
        )
    }

    private var mouseButtonBinding: Binding<ActionConfig.MouseClickAction.MouseButton> {
        Binding(
            get: {
                if case .mouseClick(let a) = binding.action { return a.button }
                return .left
            },
            set: { newButton in
                binding.action = .mouseClick(.init(button: newButton))
            }
        )
    }

    private var scrollDxBinding: Binding<Double> {
        Binding(
            get: { if case .scroll(let a) = binding.action { return a.dx }; return 0 },
            set: { if case .scroll(var a) = binding.action { a.dx = $0; binding.action = .scroll(a) } }
        )
    }

    private var scrollDyBinding: Binding<Double> {
        Binding(
            get: { if case .scroll(let a) = binding.action { return a.dy }; return 0 },
            set: { if case .scroll(var a) = binding.action { a.dy = $0; binding.action = .scroll(a) } }
        )
    }

    private var holdTypeBinding: Binding<String> {
        Binding(
            get: {
                switch binding.holdBehavior {
                case .onPress, .none: return "onPress"
                case .onRelease: return "onRelease"
                case .toggle: return "toggle"
                case .whileHeld: return "whileHeld"
                }
            },
            set: { newType in
                switch newType {
                case "onRelease": binding.holdBehavior = .onRelease
                case "toggle": binding.holdBehavior = .toggle
                case "whileHeld": binding.holdBehavior = .whileHeld(repeatIntervalMs: 100)
                default: binding.holdBehavior = nil
                }
            }
        )
    }

    private var whileHeldMsBinding: Binding<Int> {
        Binding(
            get: {
                if case .whileHeld(let ms) = binding.holdBehavior { return ms }
                return 100
            },
            set: { binding.holdBehavior = .whileHeld(repeatIntervalMs: max($0, 10)) }
        )
    }

    // MARK: - Display

    private var inputDisplayName: String {
        switch binding.input {
        case .single(let name): return name
        case .chord(let elements): return elements.joined(separator: " + ")
        case .sequence(let elements, let timeout): return elements.joined(separator: " → ") + " (\(timeout)ms)"
        }
    }

    private var actionDisplayName: String {
        switch binding.action {
        case .keyPress(let action):
            var parts = action.modifiers.map { $0.rawValue.capitalized }
            parts.append(action.key ?? "Key \(action.keyCode)")
            return parts.joined(separator: "+")
        case .mouseClick(let action): return "Mouse \(action.button.rawValue.capitalized)"
        case .mouseMove: return "Mouse Move"
        case .scroll(let action): return "Scroll (\(Int(action.dx)), \(Int(action.dy)))"
        case .macro(let action): return "Macro: \(action.name ?? "\(action.steps.count) steps")"
        case .shell(let action): return "Shell: \(action.command)"
        case .profileSwitch(let name): return "Profile: \(name)"
        case .layerToggle(let name): return "Layer: \(name)"
        case .none: return "None"
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
