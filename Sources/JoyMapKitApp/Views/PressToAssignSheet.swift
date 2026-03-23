import SwiftUI
import GameController
import JoyMapKitCore

/// Modal sheet that captures the next gamepad button press and returns the element name.
struct PressToAssignSheet: View {
    @Binding var capturedElement: String?
    @Binding var isPresented: Bool

    @State private var lastElement: String?
    @State private var controllerManager: ControllerManager?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Press a button on your controller")
                .font(.title3.weight(.medium))

            if let lastElement {
                Text(lastElement)
                    .font(.headline)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            } else {
                Text("Waiting for input...")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Cancel") {
                    stopListening()
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                if lastElement != nil {
                    Button("Confirm") {
                        capturedElement = lastElement
                        stopListening()
                        isPresented = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(32)
        .frame(minWidth: 300)
        .onAppear { startListening() }
        .onDisappear { stopListening() }
    }

    private func startListening() {
        let manager = ControllerManager(enableBackgroundMonitoring: false)
        self.controllerManager = manager

        manager.onInputChanged = { _, elementName, value in
            // Only capture button presses (not axes/releases)
            guard value > 0.5 else { return }
            // Filter out axis-style events (contain "Axis")
            guard !elementName.contains("Axis") else { return }

            Task { @MainActor in
                lastElement = elementName
            }
        }

        manager.startMonitoring()
    }

    private func stopListening() {
        controllerManager?.stopMonitoring()
        controllerManager = nil
    }
}
