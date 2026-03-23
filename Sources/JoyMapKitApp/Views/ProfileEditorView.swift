import SwiftUI
import AppKit
import JoyMapKitCore

private extension NSAlert {
    static func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

/// Main profile editing interface with tabs for bindings, sticks, and triggers.
struct ProfileEditorView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var editableProfile: Profile?
    @State private var selectedProfileName: String?
    @State private var hasChanges = false
    @State private var selectedTab = 0
    @State private var showTurboAssign = false

    var body: some View {
        VStack(spacing: 0) {
            // Profile selector toolbar
            HStack {
                Picker("Profile", selection: $selectedProfileName) {
                    Text("Select a profile...").tag(nil as String?)
                    ForEach(viewModel.profiles) { profile in
                        Text(profile.name).tag(profile.name as String?)
                    }
                }
                .frame(width: 200)

                Spacer()

                if editableProfile != nil {
                    HStack(spacing: 8) {
                        if hasChanges {
                            Circle()
                                .fill(.orange)
                                .frame(width: 8, height: 8)
                            Text("Unsaved changes")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        Button("Revert") {
                            loadProfile(selectedProfileName)
                        }
                        .disabled(!hasChanges)

                        Button("Save") {
                            saveProfile()
                        }
                        .disabled(!hasChanges)
                        .keyboardShortcut("s", modifiers: .command)
                    }
                }
            }
            .padding()

            Divider()

            if let _ = editableProfile {
                TabView(selection: $selectedTab) {
                    bindingsTab
                        .tabItem { Label("Bindings", systemImage: "keyboard") }
                        .tag(0)

                    sticksTab
                        .tabItem { Label("Sticks", systemImage: "l.joystick") }
                        .tag(1)

                    triggersTab
                        .tabItem { Label("Triggers", systemImage: "r2.button.roundedtop.horizontal") }
                        .tag(2)

                    turboTab
                        .tabItem { Label("Turbo", systemImage: "bolt.fill") }
                        .tag(3)
                }
                .padding()
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Select a profile to edit")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .onChange(of: selectedProfileName) { newValue in
            loadProfile(newValue)
        }
        .onAppear {
            if selectedProfileName == nil, let first = viewModel.profiles.first {
                selectedProfileName = first.name
            }
        }
    }

    // MARK: - Bindings Tab

    private var bindingsTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Button Bindings")
                    .font(.headline)
                Spacer()
                Button {
                    addBinding()
                } label: {
                    Label("Add Binding", systemImage: "plus")
                }
            }
            .padding(.bottom, 8)

            if editableProfile?.bindings.isEmpty ?? true {
                Text("No bindings configured. Click + to add one.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                List {
                    ForEach(bindingIndices, id: \.self) { index in
                        BindingRowView(binding: bindingBinding(at: index))
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    removeBinding(at: index)
                                }
                            }
                    }
                    .onDelete { offsets in
                        editableProfile?.bindings.remove(atOffsets: offsets)
                        hasChanges = true
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }

    // MARK: - Sticks Tab

    private var sticksTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if editableProfile?.sticks.isEmpty ?? true {
                    Text("No stick configurations.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 40)
                } else {
                    ForEach(stickNames, id: \.self) { name in
                        StickConfigView(
                            stickName: name,
                            config: stickBinding(for: name)
                        )
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Triggers Tab

    private var triggersTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if editableProfile?.triggers.isEmpty ?? true {
                    Text("No trigger configurations.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 40)
                } else {
                    ForEach(triggerNames, id: \.self) { name in
                        TriggerConfigView(
                            triggerName: name,
                            config: triggerBinding(for: name)
                        )
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Turbo Tab

    private var turboTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Turbo Mode")
                .font(.headline)

            Text("Assign a button as the turbo modifier. Hold it and press any other button to toggle rapid-fire on that button.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 12) {
                Text("Turbo Button:")
                    .frame(width: 100, alignment: .trailing)

                if let turboButton = editableProfile?.turboButton {
                    Text(turboButton)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))

                    Button("Change") { showTurboAssign = true }

                    Button("Remove") {
                        editableProfile?.turboButton = nil
                        hasChanges = true
                    }
                    .foregroundStyle(.red)
                } else {
                    Text("Not assigned")
                        .foregroundStyle(.secondary)

                    Button("Assign Button") { showTurboAssign = true }
                }
            }

            HStack(spacing: 12) {
                Text("Fire Rate:")
                    .frame(width: 100, alignment: .trailing)

                let rateMs = Binding<Double>(
                    get: { Double(editableProfile?.turboRateMs ?? 80) },
                    set: {
                        editableProfile?.turboRateMs = Int($0)
                        hasChanges = true
                    }
                )
                Slider(value: rateMs, in: 20...500, step: 10)
                    .frame(width: 200)

                Text("\(editableProfile?.turboRateMs ?? 80) ms")
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 60)

                Text("(\(turboRateDescription) presses/sec)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .disabled(editableProfile?.turboButton == nil)

            Spacer()
        }
        .sheet(isPresented: $showTurboAssign) {
            PressToAssignSheet(
                capturedElement: Binding(
                    get: { editableProfile?.turboButton },
                    set: { newValue in
                        editableProfile?.turboButton = newValue
                        if editableProfile?.turboRateMs == nil {
                            editableProfile?.turboRateMs = 80
                        }
                        hasChanges = true
                    }
                ),
                isPresented: $showTurboAssign
            )
        }
    }

    private var turboRateDescription: String {
        let ms = editableProfile?.turboRateMs ?? 80
        let rate = 1000.0 / Double(max(ms, 1))
        return String(format: "%.0f", rate)
    }

    // MARK: - Helpers

    private var bindingIndices: Range<Int> {
        0..<(editableProfile?.bindings.count ?? 0)
    }

    private var stickNames: [String] {
        editableProfile?.sticks.keys.sorted() ?? []
    }

    private var triggerNames: [String] {
        editableProfile?.triggers.keys.sorted() ?? []
    }

    private func bindingBinding(at index: Int) -> Binding<BindingConfig> {
        Binding(
            get: { editableProfile?.bindings[index] ?? BindingConfig(input: .single(""), action: .none) },
            set: { newValue in
                editableProfile?.bindings[index] = newValue
                hasChanges = true
            }
        )
    }

    private func stickBinding(for name: String) -> Binding<StickConfig> {
        Binding(
            get: { editableProfile?.sticks[name] ?? StickConfig() },
            set: { newValue in
                editableProfile?.sticks[name] = newValue
                hasChanges = true
            }
        )
    }

    private func triggerBinding(for name: String) -> Binding<TriggerConfig> {
        Binding(
            get: { editableProfile?.triggers[name] ?? TriggerConfig() },
            set: { newValue in
                editableProfile?.triggers[name] = newValue
                hasChanges = true
            }
        )
    }

    private func addBinding() {
        let newBinding = BindingConfig(
            input: .single("Button A"),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 36, key: "Return"))
        )
        editableProfile?.bindings.append(newBinding)
        hasChanges = true
    }

    private func removeBinding(at index: Int) {
        editableProfile?.bindings.remove(at: index)
        hasChanges = true
    }

    private func loadProfile(_ name: String?) {
        guard let name else {
            editableProfile = nil
            return
        }
        let store = ProfileStore(configDirectory: ConfigManager.defaultConfigDirectory)
        if let profile = try? store.load(name: name) {
            editableProfile = profile
            hasChanges = false
        }
    }

    private func saveProfile() {
        guard let profile = editableProfile else { return }
        let store = ProfileStore(configDirectory: ConfigManager.defaultConfigDirectory)
        do {
            try store.save(profile)
            hasChanges = false
            viewModel.reloadProfiles()
        } catch {
            NSAlert.showError("Failed to save profile: \(error.localizedDescription)")
        }
    }
}
