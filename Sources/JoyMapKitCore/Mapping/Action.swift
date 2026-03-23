import Foundation
import CoreGraphics

/// All possible output actions that can be triggered by a gamepad input.
public enum ActionConfig: Codable, Equatable {
    case keyPress(KeyPressAction)
    case mouseClick(MouseClickAction)
    case mouseMove(MouseMoveAction)
    case scroll(ScrollAction)
    case macro(MacroAction)
    case shell(ShellAction)
    case profileSwitch(String)
    case layerToggle(String)
    case none

    public struct KeyPressAction: Codable, Equatable {
        public var keyCode: UInt16
        public var modifiers: [Modifier]
        public var key: String?

        public enum Modifier: String, Codable, Equatable {
            case command, option, control, shift, fn
        }

        public init(keyCode: UInt16, modifiers: [Modifier] = [], key: String? = nil) {
            self.keyCode = keyCode
            self.modifiers = modifiers
            self.key = key
        }

        /// Convert modifiers to CGEventFlags.
        public var eventFlags: CGEventFlags {
            var flags = CGEventFlags()
            for modifier in modifiers {
                switch modifier {
                case .command:  flags.insert(.maskCommand)
                case .option:   flags.insert(.maskAlternate)
                case .control:  flags.insert(.maskControl)
                case .shift:    flags.insert(.maskShift)
                case .fn:       flags.insert(.maskSecondaryFn)
                }
            }
            return flags
        }
    }

    public struct MouseClickAction: Codable, Equatable {
        public var button: MouseButton

        public enum MouseButton: String, Codable, Equatable {
            case left, right, middle
        }

        public init(button: MouseButton) {
            self.button = button
        }
    }

    public struct MouseMoveAction: Codable, Equatable {
        public var dx: Double
        public var dy: Double

        public init(dx: Double, dy: Double) {
            self.dx = dx
            self.dy = dy
        }
    }

    public struct ScrollAction: Codable, Equatable {
        public var dx: Double
        public var dy: Double

        public init(dx: Double, dy: Double) {
            self.dx = dx
            self.dy = dy
        }
    }

    public struct MacroAction: Codable, Equatable {
        public var name: String?
        public var steps: [MacroStep]
        public var repeatCount: Int

        public struct MacroStep: Codable, Equatable {
            public var action: ActionConfig
            public var delayMs: Int
            public var holdMs: Int?

            public init(action: ActionConfig, delayMs: Int = 0, holdMs: Int? = nil) {
                self.action = action
                self.delayMs = delayMs
                self.holdMs = holdMs
            }
        }

        public init(name: String? = nil, steps: [MacroStep], repeatCount: Int = 1) {
            self.name = name
            self.steps = steps
            self.repeatCount = repeatCount
        }
    }

    public struct ShellAction: Codable, Equatable {
        public var command: String
        public var arguments: [String]

        public init(command: String, arguments: [String] = []) {
            self.command = command
            self.arguments = arguments
        }
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
    }

    private enum ActionType: String, Codable {
        case keyPress, mouseClick, mouseMove, scroll, macro, shell, profileSwitch, layerToggle, none
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ActionType.self, forKey: .type)

        switch type {
        case .keyPress:
            self = .keyPress(try KeyPressAction(from: decoder))
        case .mouseClick:
            self = .mouseClick(try MouseClickAction(from: decoder))
        case .mouseMove:
            self = .mouseMove(try MouseMoveAction(from: decoder))
        case .scroll:
            self = .scroll(try ScrollAction(from: decoder))
        case .macro:
            self = .macro(try MacroAction(from: decoder))
        case .shell:
            self = .shell(try ShellAction(from: decoder))
        case .profileSwitch:
            let singleContainer = try decoder.container(keyedBy: ProfileSwitchKeys.self)
            self = .profileSwitch(try singleContainer.decode(String.self, forKey: .profileName))
        case .layerToggle:
            let singleContainer = try decoder.container(keyedBy: LayerToggleKeys.self)
            self = .layerToggle(try singleContainer.decode(String.self, forKey: .layerName))
        case .none:
            self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .keyPress(let action):
            try container.encode(ActionType.keyPress, forKey: .type)
            try action.encode(to: encoder)
        case .mouseClick(let action):
            try container.encode(ActionType.mouseClick, forKey: .type)
            try action.encode(to: encoder)
        case .mouseMove(let action):
            try container.encode(ActionType.mouseMove, forKey: .type)
            try action.encode(to: encoder)
        case .scroll(let action):
            try container.encode(ActionType.scroll, forKey: .type)
            try action.encode(to: encoder)
        case .macro(let action):
            try container.encode(ActionType.macro, forKey: .type)
            try action.encode(to: encoder)
        case .shell(let action):
            try container.encode(ActionType.shell, forKey: .type)
            try action.encode(to: encoder)
        case .profileSwitch(let name):
            try container.encode(ActionType.profileSwitch, forKey: .type)
            var profileContainer = encoder.container(keyedBy: ProfileSwitchKeys.self)
            try profileContainer.encode(name, forKey: .profileName)
        case .layerToggle(let name):
            try container.encode(ActionType.layerToggle, forKey: .type)
            var layerContainer = encoder.container(keyedBy: LayerToggleKeys.self)
            try layerContainer.encode(name, forKey: .layerName)
        case .none:
            try container.encode(ActionType.none, forKey: .type)
        }
    }

    private enum ProfileSwitchKeys: String, CodingKey { case profileName }
    private enum LayerToggleKeys: String, CodingKey { case layerName }
}
