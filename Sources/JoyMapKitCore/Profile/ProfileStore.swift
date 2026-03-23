import Foundation
import Logging

public enum ProfileStoreError: Error, LocalizedError {
    case invalidProfileName(String)

    public var errorDescription: String? {
        switch self {
        case .invalidProfileName(let name):
            return "Invalid profile name: '\(name)'"
        }
    }
}

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
        guard let url = sanitizedProfileURL(for: name) else {
            throw ProfileStoreError.invalidProfileName(name)
        }
        return try load(from: url)
    }

    public func save(_ profile: Profile) throws {
        guard let url = sanitizedProfileURL(for: profile.name) else {
            throw ProfileStoreError.invalidProfileName(profile.name)
        }

        try FileManager.default.createDirectory(
            at: profilesDirectory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(profile)
        try data.write(to: url, options: .atomic)
        logger.info("Saved profile: \(profile.name)")
    }

    public func delete(name: String) throws {
        guard let url = sanitizedProfileURL(for: name) else {
            throw ProfileStoreError.invalidProfileName(name)
        }
        try FileManager.default.removeItem(at: url)
        logger.info("Deleted profile: \(name)")
    }

    public func exists(name: String) -> Bool {
        guard let url = sanitizedProfileURL(for: name) else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }

    // MARK: - Private

    private func sanitizedProfileURL(for name: String) -> URL? {
        let sanitized = name.replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "..", with: "")
            .replacingOccurrences(of: "\0", with: "")
        guard !sanitized.isEmpty else { return nil }
        let url = profilesDirectory.appendingPathComponent("\(sanitized).json")
        let resolved = url.standardizedFileURL.path
        guard resolved.hasPrefix(profilesDirectory.standardizedFileURL.path) else { return nil }
        return url
    }

    private func load(from url: URL) throws -> Profile {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Profile.self, from: data)
    }
}
