import ArgumentParser
import Foundation
import JoyMapKitCore
import GameController

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List connected controllers or saved profiles",
        subcommands: [ListControllers.self, ListProfiles.self],
        defaultSubcommand: ListControllers.self
    )
}

struct ListControllers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "controllers",
        abstract: "List connected game controllers"
    )

    @Flag(name: .long, help: "Output in JSON format")
    var json: Bool = false

    func run() async throws {
        // Need a brief run loop to let GameController discover devices
        let controllers = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                // Give the framework a moment to enumerate
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    let controllers = GCController.controllers()
                    continuation.resume(returning: controllers)
                }
                RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))
            }
        }

        if json {
            printControllersJSON(controllers)
        } else {
            printControllersTable(controllers)
        }
    }

    private func printControllersTable(_ controllers: [GCController]) {
        if controllers.isEmpty {
            print("No controllers connected.")
            return
        }

        print("Connected Controllers:")
        print(String(repeating: "─", count: 70))
        for (index, controller) in controllers.enumerated() {
            let name = controller.vendorName ?? "Unknown"
            let category = controller.productCategory
            let elements = controller.physicalInputProfile.elements.count
            print("  [\(index)] \(name)")
            print("      Category: \(category)")
            print("      Elements: \(elements)")

            if let gamepad = controller.extendedGamepad {
                var type = "Generic"
                if gamepad is GCXboxGamepad { type = "Xbox" }
                else if gamepad is GCDualSenseGamepad { type = "DualSense" }
                else if gamepad is GCDualShockGamepad { type = "DualShock" }
                print("      Type: \(type)")
            }
            print()
        }
    }

    private func printControllersJSON(_ controllers: [GCController]) {
        var result: [[String: Any]] = []
        for controller in controllers {
            var info: [String: Any] = [
                "vendorName": controller.vendorName ?? "Unknown",
                "productCategory": controller.productCategory,
                "elementCount": controller.physicalInputProfile.elements.count,
            ]
            let elements = controller.physicalInputProfile.elements
            info["elements"] = Array(elements.keys).sorted()
            result.append(info)
        }

        if let data = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted),
           let string = String(data: data, encoding: .utf8) {
            print(string)
        }
    }
}

struct ListProfiles: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "profiles",
        abstract: "List saved mapping profiles"
    )

    @Option(name: .long, help: "Config directory path")
    var configDir: String?

    func run() async throws {
        let configDirectory: URL
        if let configDir {
            configDirectory = URL(fileURLWithPath: configDir)
        } else {
            configDirectory = ConfigManager.defaultConfigDirectory
        }

        let store = ProfileStore(configDirectory: configDirectory)
        let profiles = (try? store.loadAll()) ?? []

        if profiles.isEmpty {
            print("No profiles found in \(configDirectory.path)/profiles/")
            print("Create one with: joymapkit profile create <name>")
            return
        }

        print("Profiles:")
        print(String(repeating: "─", count: 60))
        for profile in profiles {
            let apps = profile.appBundleIDs.joined(separator: ", ")
            let bindings = profile.bindings.count
            print("  \(profile.name)")
            print("    Apps: \(apps)")
            print("    Bindings: \(bindings)")
            if let desc = profile.metadata?.description {
                print("    Description: \(desc)")
            }
            print()
        }
    }
}
