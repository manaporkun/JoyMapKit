import Foundation
import Logging

/// Protocol for dispatching output actions, enabling testability.
public protocol ActionDispatching {
    func dispatch(_ action: ActionConfig, pressed: Bool) throws
}

/// Executes output actions by delegating to appropriate simulators.
public final class ActionDispatcher: ActionDispatching {
    private let keySimulator: KeySimulating
    private let mouseSimulator: MouseSimulating
    private let logger = Logger(label: "com.joymapkit.dispatcher")

    /// Called when a macro action is dispatched (pressed=true starts, pressed=false cancels).
    public var onMacro: ((_ macro: ActionConfig.MacroAction, _ key: String, _ pressed: Bool) -> Void)?

    /// Called when a profile switch action is dispatched.
    public var onProfileSwitch: ((_ profileName: String) -> Void)?

    /// Called when a layer toggle action is dispatched.
    public var onLayerToggle: ((_ layerName: String) -> Void)?

    public init(keySimulator: KeySimulating, mouseSimulator: MouseSimulating) {
        self.keySimulator = keySimulator
        self.mouseSimulator = mouseSimulator
    }

    public func dispatch(_ action: ActionConfig, pressed: Bool) throws {
        switch action {
        case .keyPress(let keyAction):
            if pressed {
                try keySimulator.pressKey(code: keyAction.keyCode, flags: keyAction.eventFlags)
            } else {
                try keySimulator.releaseKey(code: keyAction.keyCode, flags: keyAction.eventFlags)
            }

        case .mouseClick(let clickAction):
            try mouseSimulator.click(button: clickAction.button, down: pressed)

        case .mouseMove(let moveAction):
            if pressed {
                try mouseSimulator.moveMouse(dx: moveAction.dx, dy: moveAction.dy)
            }

        case .scroll(let scrollAction):
            if pressed {
                try mouseSimulator.scroll(dx: scrollAction.dx, dy: scrollAction.dy)
            }

        case .shell(let shellAction):
            if pressed {
                executeShell(shellAction)
            }

        case .macro(let macroAction):
            onMacro?(macroAction, macroAction.name ?? UUID().uuidString, pressed)

        case .profileSwitch(let name):
            if pressed {
                onProfileSwitch?(name)
            }

        case .layerToggle(let name):
            if pressed {
                onLayerToggle?(name)
            }

        case .none:
            break
        }
    }

    private func executeShell(_ action: ActionConfig.ShellAction) {
        DispatchQueue.global(qos: .utility).async { [logger] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: action.command)
            process.arguments = action.arguments
            do {
                try process.run()
            } catch {
                logger.error("Shell action failed: \(error)")
            }
        }
    }
}
