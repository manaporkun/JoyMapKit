import ArgumentParser

@main
struct JoyMapKitCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "joymapkit",
        abstract: "Gamepad-to-keyboard/mouse mapper for macOS",
        version: "0.1.0",
        subcommands: [
            RunCommand.self,
            TestCommand.self,
            ListCommand.self,
        ],
        defaultSubcommand: RunCommand.self
    )
}
