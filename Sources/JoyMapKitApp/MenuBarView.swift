import SwiftUI
import JoyMapKitCore

struct MenuBarView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var isHoveringQuit = false
    @State private var pulseConnection = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient accent
            EmptyView().onAppear { viewModel.recheckAccessibility() }
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("JoyMapKit")
                        .font(.headline)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.isEnabled },
                    set: { _ in
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.toggle()
                        }
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
                .tint(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().opacity(0.5)

            // Controllers section
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader("Controllers", icon: "gamecontroller")

                if viewModel.controllers.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.secondary)
                            .opacity(pulseConnection ? 0.4 : 1.0)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseConnection)
                        Text("No controllers connected")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                    .onAppear { pulseConnection = true }
                } else {
                    ForEach(viewModel.controllers) { controller in
                        controllerRow(controller)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .animation(.spring(response: 0.4), value: viewModel.controllers.count)

            Divider().opacity(0.5)

            // Profile section
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader("Profile", icon: "slider.horizontal.3")

                if viewModel.profiles.isEmpty {
                    Text("No profiles configured")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ForEach(viewModel.profiles) { profile in
                        profileRow(profile)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().opacity(0.5)

            // Accessibility warning
            if !viewModel.accessibilityGranted {
                accessibilityBanner
                Divider().opacity(0.5)
            }

            // Actions grid
            VStack(spacing: 2) {
                menuAction(icon: "waveform.path.ecg", label: "Input Monitor", color: .blue) {
                    viewModel.showInputMonitor = true
                    openWindow(id: "input-monitor")
                }

                menuAction(icon: "gamecontroller.fill", label: "Controller Test", color: .green) {
                    openWindow(id: "controller-test")
                }

                menuAction(icon: "pencil.and.list.clipboard", label: "Edit Profile", color: .orange) {
                    openWindow(id: "profile-editor")
                }

                menuAction(icon: "music.note.list", label: "Rhythm Game", color: .purple) {
                    openWindow(id: "rhythm-game")
                }

                menuAction(icon: "folder", label: "Open Config Folder", color: .secondary) {
                    let configDir = ConfigManager.defaultConfigDirectory
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: configDir.path)
                }
            }
            .padding(.vertical, 4)

            Divider().opacity(0.5)

            // Footer
            HStack {
                Button("About") {
                    openWindow(id: "about")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .foregroundStyle(isHoveringQuit ? .red : .secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .onHover { isHoveringQuit = $0 }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Components

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func controllerRow(_ controller: AppViewModel.ControllerInfo) -> some View {
        HStack(spacing: 10) {
            Image(systemName: controllerIcon(for: controller.type))
                .foregroundStyle(.blue)
                .font(.body)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(controller.name)
                    .font(.callout)
                Text("\(controller.type) \u{2022} \(controller.elementCount) inputs")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(.green)
                .frame(width: 6, height: 6)
                .shadow(color: .green.opacity(0.5), radius: 3)
        }
    }

    private func profileRow(_ profile: AppViewModel.ProfileInfo) -> some View {
        let isActive = viewModel.activeProfileName == profile.name

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                viewModel.selectProfile(profile.name)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isActive ? .blue : .secondary)
                    .font(.body)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(profile.name)
                        .font(.callout)
                        .fontWeight(isActive ? .medium : .regular)
                    Text("\(profile.bindingCount) bindings")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isActive {
                    Text("Active")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1), in: Capsule())
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var accessibilityBanner: some View {
        Button(action: { viewModel.requestAccessibility() }) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Accessibility Required")
                        .font(.callout.weight(.medium))
                    Text("Click to grant permission")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.orange.opacity(0.05))
        }
        .buttonStyle(.plain)
    }

    private func menuAction(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 20)
                Text(label)
                    .font(.callout)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func controllerIcon(for type: String) -> String {
        switch type {
        case "xbox": return "xbox.logo"
        case "dualSense", "dualShock": return "playstation.logo"
        default: return "gamecontroller.fill"
        }
    }
}
