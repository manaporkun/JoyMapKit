import Foundation

/// Processes raw analog stick input through deadzone, response curve, and sensitivity.
public struct StickProcessor {
    public var config: StickConfig

    public init(config: StickConfig) {
        self.config = config
    }

    /// Process raw stick input values.
    /// - Parameters:
    ///   - rawX: Raw X axis value in range -1.0 to 1.0
    ///   - rawY: Raw Y axis value in range -1.0 to 1.0
    /// - Returns: Processed values in range -1.0 to 1.0
    public func process(rawX: Float, rawY: Float) -> (x: Double, y: Double) {
        let x = Double(rawX)
        let y = Double(rawY)

        // 1. Compute radial magnitude (circular deadzone, not per-axis diamond)
        let magnitude = sqrt(x * x + y * y)

        guard magnitude > config.deadzone else {
            return (0, 0)
        }

        // 2. Apply outer deadzone
        let effectiveMagnitude = min(magnitude, config.outerDeadzone)

        // 3. Remap to 0-1 range within deadzones
        let range = config.outerDeadzone - config.deadzone
        guard range > 0 else { return (0, 0) }
        let normalized = (effectiveMagnitude - config.deadzone) / range

        // 4. Apply response curve
        let curve = ResponseCurve(from: config.responseCurve)
        let curved = curve.apply(normalized)

        // 5. Apply sensitivity and reconstruct directional vector
        let angle = atan2(y, x)
        let finalMagnitude = curved * config.sensitivity

        return (
            x: finalMagnitude * cos(angle),
            y: finalMagnitude * sin(angle)
        )
    }
}
