import Foundation
import Logging

/// Converts processed stick output to mouse movement, driven by an external tick.
public final class MouseDriver {
    public var maxSpeed: Double = 1500.0
    public var sensitivity: Double = 1.0

    private var currentX: Double = 0
    private var currentY: Double = 0
    private var tickInterval: Double = 1.0 / 120.0
    private let mouseSimulator: MouseSimulating
    private let logger = Logger(label: "com.joymapkit.mouse")

    public init(mouseSimulator: MouseSimulating) {
        self.mouseSimulator = mouseSimulator
    }

    /// Update the current stick input. Called from the input handler.
    public func updateInput(x: Double, y: Double) {
        currentX = x
        currentY = y
    }

    /// Store the tick interval without creating a timer. The external caller drives ticks.
    public func configure(tickRate: Int) {
        tickInterval = 1.0 / Double(max(tickRate, 1))
    }

    /// Advance one frame of mouse movement. Called by AnalogHandler's unified tick timer.
    public func tick() {
        guard abs(currentX) > 0.001 || abs(currentY) > 0.001 else { return }

        let dx = currentX * maxSpeed * sensitivity * tickInterval
        let dy = -currentY * maxSpeed * sensitivity * tickInterval  // Invert Y for screen coords

        do { try mouseSimulator.moveMouse(dx: dx, dy: dy) }
        catch { logger.error("Mouse move failed: \(error)") }
    }
}
