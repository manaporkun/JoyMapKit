import Foundation

/// Identifies a running application by its bundle ID and display name.
public struct AppIdentifier: Equatable, Codable, CustomStringConvertible {
    public let bundleID: String
    public let displayName: String

    public init(bundleID: String, displayName: String) {
        self.bundleID = bundleID
        self.displayName = displayName
    }

    public var description: String { "\(displayName) (\(bundleID))" }
}
