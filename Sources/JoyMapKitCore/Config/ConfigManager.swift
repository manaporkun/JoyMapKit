import Foundation
import Logging

/// Manages loading and saving of global configuration.
public final class ConfigManager: Sendable {
    private let configDirectory: URL
    private let logger = Logger(label: "com.joymapkit.config")

    public var configFileURL: URL {
        configDirectory.appendingPathComponent("config.json")
    }

    public init(configDirectory: URL) {
        self.configDirectory = configDirectory
    }

    public func load() throws -> GlobalConfig {
        let url = configFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.info("No config file found, using defaults")
            return GlobalConfig()
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GlobalConfig.self, from: data)
    }

    public func save(_ config: GlobalConfig) throws {
        try FileManager.default.createDirectory(
            at: configDirectory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(config)
        try data.write(to: configFileURL, options: .atomic)
    }

    public func ensureDefaults() throws {
        guard !FileManager.default.fileExists(atPath: configFileURL.path) else { return }
        try save(GlobalConfig())
        logger.info("Created default config at \(configFileURL.path)")
    }

    public static var defaultConfigDirectory: URL {
        if let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
            return URL(fileURLWithPath: xdg).appendingPathComponent("joymapkit")
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/joymapkit")
    }
}
