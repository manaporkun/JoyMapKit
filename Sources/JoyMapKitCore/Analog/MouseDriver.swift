import Foundation

/// Converts processed stick output to mouse movement at a fixed tick rate.
/// Phase 2 implementation — placeholder for now.
public final class MouseDriver {
    public var maxSpeed: Double = 1500.0
    public var sensitivity: Double = 1.0

    private var timer: Timer?
    private var currentX: Double = 0
    private var currentY: Double = 0
    private let mouseSimulator: MouseSimulating

    public init(mouseSimulator: MouseSimulating) {
        self.mouseSimulator = mouseSimulator
    }

    /// Update the current stick input. Called from the input handler.
    public func updateInput(x: Double, y: Double) {
        currentX = x
        currentY = y
    }

    /// Start the tick loop for continuous mouse movement.
    public func start(tickRate: Int = 120) {
        let interval = 1.0 / Double(tickRate)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick(interval: interval)
        }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick(interval: Double) {
        guard abs(currentX) > 0.001 || abs(currentY) > 0.001 else { return }

        let dx = currentX * maxSpeed * sensitivity * interval
        let dy = -currentY * maxSpeed * sensitivity * interval  // Invert Y for screen coords

        try? mouseSimulator.moveMouse(dx: dx, dy: dy)
    }
}
