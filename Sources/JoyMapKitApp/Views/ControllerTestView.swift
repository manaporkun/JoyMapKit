import SwiftUI
import GameController
import JoyMapKitCore

/// Window that shows the live controller visualization with real-time button/stick/trigger feedback.
struct ControllerTestView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var inputStates: [String: Float] = [:]
    @State private var controllerManager: ControllerManager?
    @State private var connectedName: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundStyle(.blue)
                Text("Controller Test")
                    .font(.headline)

                Spacer()

                if let name = connectedName {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: .green.opacity(0.5), radius: 3)
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity)
                } else {
                    Text("No controller")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .animation(.easeInOut, value: connectedName)

            Divider()

            if connectedName != nil {
                ControllerVisualizationView(inputStates: inputStates)
                    .padding(24)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                        .opacity(0.5)
                    Text("Connect a controller to begin")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Press buttons and move sticks to see them light up")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .transition(.opacity)
                Spacer()
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { startListening() }
        .onDisappear { stopListening() }
    }

    private func startListening() {
        let manager = ControllerManager(enableBackgroundMonitoring: false)
        self.controllerManager = manager

        manager.onControllerConnected = { handle in
            Task { @MainActor in
                withAnimation { connectedName = handle.vendorName }
            }
        }

        manager.onControllerDisconnected = { _ in
            Task { @MainActor in
                withAnimation {
                    connectedName = nil
                    inputStates.removeAll()
                }
            }
        }

        manager.onInputChanged = { _, elementName, value in
            Task { @MainActor in
                inputStates[elementName] = value
            }
        }

        manager.startMonitoring()
    }

    private func stopListening() {
        controllerManager?.stopMonitoring()
        controllerManager = nil
    }
}
