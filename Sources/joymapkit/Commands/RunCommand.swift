import ArgumentParser
import Foundation
import JoyMapKitCore

struct RunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Start the mapping service in the foreground"
    )

    @Option(name: .long, help: "Override active profile by name")
    var profile: String?

    @Flag(name: .long, help: "Disable automatic profile switching on app focus change")
    var noAutoSwitch: Bool = false

    @Option(name: .long, help: "Config directory path (default: ~/.config/joymapkit)")
    var configDir: String?

    func run() async throws {
        let configDirectory: URL?
        if let configDir {
            configDirectory = URL(fileURLWithPath: configDir)
        } else {
            configDirectory = nil
        }

        let service = try JoyMapService(configDirectory: configDirectory)

        // Handle SIGINT/SIGTERM for clean shutdown
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        signal(SIGINT, SIG_IGN)
        signalSource.setEventHandler {
            print("\nShutting down...")
            service.stop()
            Foundation.exit(0)
        }
        signalSource.resume()

        let termSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        signal(SIGTERM, SIG_IGN)
        termSource.setEventHandler {
            service.stop()
            Foundation.exit(0)
        }
        termSource.resume()

        try service.start(
            profileOverride: profile,
            autoSwitch: !noAutoSwitch
        )

        print("JoyMapKit running. Press Ctrl+C to stop.")
        if service.status.connectedControllers.isEmpty {
            print("No controllers detected. Connect a gamepad to begin.")
        } else {
            for controller in service.status.connectedControllers {
                print("  Controller: \(controller.name) (\(controller.type.rawValue))")
            }
        }
        if let profileName = service.status.activeProfileName {
            print("  Active profile: \(profileName)")
        }

        // Keep alive using async-compatible approach
        while true {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
