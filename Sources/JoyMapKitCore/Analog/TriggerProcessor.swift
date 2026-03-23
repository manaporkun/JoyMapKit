import Foundation

/// Processes analog trigger input for digital threshold conversion or continuous output.
public struct TriggerProcessor {
    public var config: TriggerConfig

    public init(config: TriggerConfig) {
        self.config = config
    }

    /// Process raw trigger value.
    /// - Parameter rawValue: Raw trigger value in range 0.0 to 1.0
    /// - Returns: Processed digital state and analog value
    public func process(rawValue: Float) -> (isPressed: Bool, analogValue: Double) {
        let value = Double(rawValue)

        switch config.mode {
        case .digital:
            return (value >= config.threshold, value)
        case .analog:
            return (value > 0, value)
        case .mouseScroll:
            return (value > 0.05, value)
        case .disabled:
            return (false, 0)
        }
    }
}
