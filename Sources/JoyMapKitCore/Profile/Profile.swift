import Foundation

/// A complete mapping profile that defines how gamepad inputs map to actions.
public struct Profile: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var version: Int
    public var metadata: ProfileMetadata?
    public var appBundleIDs: [String]
    public var controllerTypes: [ControllerType]?
    public var bindings: [BindingConfig]
    public var layers: [LayerConfig]
    public var sticks: [String: StickConfig]
    public var triggers: [String: TriggerConfig]
    public var turboButton: String?
    public var turboRateMs: Int?

    public init(
        id: UUID = UUID(),
        name: String,
        version: Int = 1,
        metadata: ProfileMetadata? = nil,
        appBundleIDs: [String] = ["*"],
        controllerTypes: [ControllerType]? = nil,
        bindings: [BindingConfig] = [],
        layers: [LayerConfig] = [],
        sticks: [String: StickConfig] = [:],
        triggers: [String: TriggerConfig] = [:],
        turboButton: String? = nil,
        turboRateMs: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.metadata = metadata
        self.appBundleIDs = appBundleIDs
        self.controllerTypes = controllerTypes
        self.bindings = bindings
        self.layers = layers
        self.sticks = sticks
        self.triggers = triggers
        self.turboButton = turboButton
        self.turboRateMs = turboRateMs
    }
}

public struct ProfileMetadata: Codable, Equatable {
    public var author: String?
    public var description: String?
    public var createdAt: Date?
    public var modifiedAt: Date?

    public init(author: String? = nil, description: String? = nil) {
        self.author = author
        self.description = description
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

public enum ControllerType: String, Codable, Equatable {
    case xbox, dualSense, dualShock, nintendoPro, generic
}

public struct LayerConfig: Codable, Equatable {
    public var name: String
    public var activator: InputSpec
    public var bindings: [BindingConfig]

    public init(name: String, activator: InputSpec, bindings: [BindingConfig]) {
        self.name = name
        self.activator = activator
        self.bindings = bindings
    }
}

public struct StickConfig: Codable, Equatable {
    public var mode: StickMode
    public var deadzone: Double
    public var outerDeadzone: Double
    public var responseCurve: ResponseCurveConfig
    public var sensitivity: Double
    public var scrollSpeed: Double?

    public enum StickMode: String, Codable, Equatable {
        case mouse, scroll, wasd, arrows, disabled
    }

    public init(
        mode: StickMode = .mouse,
        deadzone: Double = 0.15,
        outerDeadzone: Double = 0.95,
        responseCurve: ResponseCurveConfig = ResponseCurveConfig(),
        sensitivity: Double = 1.0,
        scrollSpeed: Double? = nil
    ) {
        self.mode = mode
        self.deadzone = deadzone
        self.outerDeadzone = outerDeadzone
        self.responseCurve = responseCurve
        self.sensitivity = sensitivity
        self.scrollSpeed = scrollSpeed
    }
}

public struct TriggerConfig: Codable, Equatable {
    public var mode: TriggerMode
    public var threshold: Double
    public var action: ActionConfig?

    public enum TriggerMode: String, Codable, Equatable {
        case digital, analog, mouseScroll, disabled
    }

    public init(
        mode: TriggerMode = .digital,
        threshold: Double = 0.3,
        action: ActionConfig? = nil
    ) {
        self.mode = mode
        self.threshold = threshold
        self.action = action
    }
}

public struct ResponseCurveConfig: Codable, Equatable {
    public var type: ResponseCurveType
    public var customPoints: [[Double]]?

    public enum ResponseCurveType: String, Codable, Equatable {
        case linear, quadratic, cubic, sCurve, custom
    }

    public init(type: ResponseCurveType = .linear, customPoints: [[Double]]? = nil) {
        self.type = type
        self.customPoints = customPoints
    }
}
