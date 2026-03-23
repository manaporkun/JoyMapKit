import Foundation

/// Normalized, controller-agnostic input identifier.
/// Uses canonical names from GCPhysicalInputProfile element keys.
public enum InputElement: Hashable, Codable, CustomStringConvertible {
    case button(String)
    case axis(String)
    case dpad(String, DPadDirection)

    public enum DPadDirection: String, Codable, CaseIterable {
        case up, down, left, right
    }

    public var canonicalName: String {
        switch self {
        case .button(let name):
            return name
        case .axis(let name):
            return name
        case .dpad(let name, let direction):
            return "\(name) \(direction.rawValue.capitalized)"
        }
    }

    public var description: String { canonicalName }

    /// Whether this element represents a digital (on/off) input.
    public var isDigital: Bool {
        switch self {
        case .button, .dpad:
            return true
        case .axis:
            return false
        }
    }
}
