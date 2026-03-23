import ArgumentParser
import Foundation
import JoyMapKitCore

@main
struct JoyMapKitCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "joymapkit",
        abstract: "Gamepad-to-keyboard/mouse mapper for macOS",
        version: JoyMapKitVersion.current,
        subcommands: [
            RunCommand.self,
            TestCommand.self,
            ListCommand.self,
        ],
        defaultSubcommand: RunCommand.self
    )
}
