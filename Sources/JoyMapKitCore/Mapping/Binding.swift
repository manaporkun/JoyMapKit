import Foundation

/// Specifies which input(s) trigger a binding.
public enum InputSpec: Codable, Hashable {
    case single(String)
    case chord([String])
    case sequence([String], timeoutMs: Int)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type, element, elements, timeoutMs
    }

    private enum InputType: String, Codable {
        case single, chord, sequence
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(InputType.self, forKey: .type)

        switch type {
        case .single:
            let element = try container.decode(String.self, forKey: .element)
            self = .single(element)
        case .chord:
            let elements = try container.decode([String].self, forKey: .elements)
            self = .chord(elements)
        case .sequence:
            let elements = try container.decode([String].self, forKey: .elements)
            let timeout = try container.decode(Int.self, forKey: .timeoutMs)
            self = .sequence(elements, timeoutMs: timeout)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .single(let element):
            try container.encode(InputType.single, forKey: .type)
            try container.encode(element, forKey: .element)
        case .chord(let elements):
            try container.encode(InputType.chord, forKey: .type)
            try container.encode(elements, forKey: .elements)
        case .sequence(let elements, let timeout):
            try container.encode(InputType.sequence, forKey: .type)
            try container.encode(elements, forKey: .elements)
            try container.encode(timeout, forKey: .timeoutMs)
        }
    }
}

/// How a binding behaves when the input is held.
public enum HoldBehavior: Codable, Equatable {
    case onPress
    case onRelease
    case whileHeld(repeatIntervalMs: Int)
    case toggle

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type, repeatIntervalMs
    }

    private enum HoldType: String, Codable {
        case onPress, onRelease, whileHeld, toggle
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(HoldType.self, forKey: .type)

        switch type {
        case .onPress:   self = .onPress
        case .onRelease: self = .onRelease
        case .whileHeld:
            let interval = try container.decode(Int.self, forKey: .repeatIntervalMs)
            self = .whileHeld(repeatIntervalMs: interval)
        case .toggle:    self = .toggle
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .onPress:
            try container.encode(HoldType.onPress, forKey: .type)
        case .onRelease:
            try container.encode(HoldType.onRelease, forKey: .type)
        case .whileHeld(let interval):
            try container.encode(HoldType.whileHeld, forKey: .type)
            try container.encode(interval, forKey: .repeatIntervalMs)
        case .toggle:
            try container.encode(HoldType.toggle, forKey: .type)
        }
    }
}

/// Links an input specification to an output action.
public struct BindingConfig: Codable, Equatable {
    public var input: InputSpec
    public var action: ActionConfig
    public var holdBehavior: HoldBehavior?
    public var layer: String?

    public init(
        input: InputSpec,
        action: ActionConfig,
        holdBehavior: HoldBehavior? = nil,
        layer: String? = nil
    ) {
        self.input = input
        self.action = action
        self.holdBehavior = holdBehavior
        self.layer = layer
    }
}
