import Foundation

/// Top-level application configuration.
public struct GlobalConfig: Codable, Equatable {
    public var version: Int
    public var general: GeneralConfig
    public var input: InputConfig
    public var mouse: MouseConfig
    public var profiles: ProfilesConfig

    public init() {
        self.version = 1
        self.general = GeneralConfig()
        self.input = InputConfig()
        self.mouse = MouseConfig()
        self.profiles = ProfilesConfig()
    }
}

public struct GeneralConfig: Codable, Equatable {
    public var logLevel: String
    public var launchAtLogin: Bool
    public var showNotificationsOnProfileSwitch: Bool
    public var showNotificationsOnControllerConnect: Bool

    public init(
        logLevel: String = "info",
        launchAtLogin: Bool = false,
        showNotificationsOnProfileSwitch: Bool = true,
        showNotificationsOnControllerConnect: Bool = true
    ) {
        self.logLevel = logLevel
        self.launchAtLogin = launchAtLogin
        self.showNotificationsOnProfileSwitch = showNotificationsOnProfileSwitch
        self.showNotificationsOnControllerConnect = showNotificationsOnControllerConnect
    }
}

public struct InputConfig: Codable, Equatable {
    public var chordWindowMs: Int
    public var backgroundMonitoring: Bool
    public var pollRateHz: Int

    public init(
        chordWindowMs: Int = 50,
        backgroundMonitoring: Bool = true,
        pollRateHz: Int = 120
    ) {
        self.chordWindowMs = chordWindowMs
        self.backgroundMonitoring = backgroundMonitoring
        self.pollRateHz = pollRateHz
    }
}

public struct MouseConfig: Codable, Equatable {
    public var globalSensitivity: Double
    public var maxSpeed: Double
    public var accelerationEnabled: Bool
    public var naturalScrolling: Bool

    public init(
        globalSensitivity: Double = 1.0,
        maxSpeed: Double = 1500.0,
        accelerationEnabled: Bool = true,
        naturalScrolling: Bool = false
    ) {
        self.globalSensitivity = globalSensitivity
        self.maxSpeed = maxSpeed
        self.accelerationEnabled = accelerationEnabled
        self.naturalScrolling = naturalScrolling
    }
}

public struct ProfilesConfig: Codable, Equatable {
    public var defaultProfile: String

    public init(defaultProfile: String = "default") {
        self.defaultProfile = defaultProfile
    }
}
