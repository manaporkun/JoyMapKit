import Foundation
import Logging

/// Manages loading and saving of mapping profiles from disk.
public final class ProfileStore {
    private let profilesDirectory: URL
    private let logger = Logger(label: "com.joymapkit.profiles")

    public init(configDirectory: URL) {
        self.profilesDirectory = configDirectory.appendingPathComponent("profiles")
    }

    public func loadAll() throws -> [Profile] {
        guard FileManager.default.fileExists(atPath: profilesDirectory.path) else {
            return []
        }

        let files = try FileManager.default.contentsOfDirectory(
            at: profilesDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        return files.compactMap { url in
            do {
                return try load(from: url)
            } catch {
                logger.warning("Failed to load profile \(url.lastPathComponent): \(error)")
                return nil
            }
        }
    }

    public func load(name: String) throws -> Profile {
        let url = profilesDirectory.appendingPathComponent("\(name).json")
        return try load(from: url)
    }

    public func save(_ profile: Profile) throws {
        try FileManager.default.createDirectory(
            at: profilesDirectory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(profile)
        let url = profilesDirectory.appendingPathComponent("\(profile.name).json")
        try data.write(to: url, options: .atomic)
        logger.info("Saved profile: \(profile.name)")
    }

    public func delete(name: String) throws {
        let url = profilesDirectory.appendingPathComponent("\(name).json")
        try FileManager.default.removeItem(at: url)
        logger.info("Deleted profile: \(name)")
    }

    public func exists(name: String) -> Bool {
        let url = profilesDirectory.appendingPathComponent("\(name).json")
        return FileManager.default.fileExists(atPath: url.path)
    }

    // MARK: - Private

    private func load(from url: URL) throws -> Profile {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Profile.self, from: data)
    }
}
