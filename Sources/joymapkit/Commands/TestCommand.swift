import ArgumentParser
import Foundation
import JoyMapKitCore
import GameController

struct TestCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Live input monitor — shows all controller events in real-time"
    )

    @Flag(name: .long, help: "Show raw analog values without filtering")
    var raw: Bool = false

    func run() async throws {
        print("JoyMapKit Input Monitor")
        print("Press Ctrl+C to exit.\n")
        print("Waiting for controller...")

        let manager = ControllerManager(enableBackgroundMonitoring: false)
        let threshold: Float = raw ? 0.0 : 0.01

        manager.onControllerConnected = { handle in
            print("\n✓ Connected: \(handle.vendorName) (\(handle.controllerType.rawValue))")
            print("  Elements: \(handle.availableElements.count)")
            print("  Available inputs:")
            for element in handle.availableElements {
                print("    - \(element)")
            }
            print("\nPress buttons or move sticks to see input events:\n")
        }

        manager.onControllerDisconnected = { handle in
            print("\n✗ Disconnected: \(handle.vendorName)\n")
        }

        manager.onInputChanged = { handle, elementName, value in
            guard abs(value) > threshold else { return }

            let timestamp = DateFormatter.localizedString(
                from: Date(), dateStyle: .none, timeStyle: .medium
            )
            let bar = String(repeating: "█", count: Int(abs(value) * 20))
            let padding = String(repeating: "░", count: 20 - Int(abs(value) * 20))
            print("[\(timestamp)] \(elementName.padding(toLength: 30, withPad: " ", startingAt: 0)) \(String(format: "%+.3f", value)) [\(bar)\(padding)]")
        }

        // Handle SIGINT
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        signal(SIGINT, SIG_IGN)
        signalSource.setEventHandler {
            print("\nStopping monitor...")
            manager.stopMonitoring()
            Foundation.exit(0)
        }
        signalSource.resume()

        manager.startMonitoring()

        // Keep alive using async-compatible approach
        while true {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
