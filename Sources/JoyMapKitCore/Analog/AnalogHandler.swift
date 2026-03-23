import Foundation
import Logging

/// Handles analog stick and trigger input processing, routing through StickProcessor/TriggerProcessor
/// and driving mouse movement, scrolling, and virtual key output at a fixed tick rate.
public final class AnalogHandler {

    // MARK: - Types

    private struct StickState {
        var processor: StickProcessor
        var config: StickConfig
        var lastRawX: Float = 0
        var lastRawY: Float = 0
        /// Direction keys currently held for wasd/arrows mode
        var heldKeys: Set<UInt16> = []
    }

    private struct TriggerState {
        var processor: TriggerProcessor
        var config: TriggerConfig
        var wasPressed: Bool = false
    }

    private enum Axis { case x, y }

    // MARK: - Dependencies

    private let mouseSimulator: MouseSimulating
    private let keySimulator: KeySimulating
    private let actionDispatcher: ActionDispatching
    private let logger = Logger(label: "com.joymapkit.analog")

    // MARK: - State

    private var sticks: [String: StickState] = [:]
    private var triggers: [String: TriggerState] = [:]
    /// Maps axis element names to their owning stick. E.g. "Left Thumbstick X Axis" → ("Left Thumbstick", .x)
    private var axisToStick: [String: (stickName: String, axis: Axis)] = [:]

    private var mouseDrivers: [String: MouseDriver] = [:]
    private var tickTimer: Timer?
    private var tickInterval: Double = 1.0 / 120.0
    private var globalMouseConfig = MouseConfig()

    // MARK: - Direction Key Maps

    private static let wasdKeys: (up: UInt16, down: UInt16, left: UInt16, right: UInt16) = (13, 1, 0, 2) // W, S, A, D
    private static let arrowKeys: (up: UInt16, down: UInt16, left: UInt16, right: UInt16) = (126, 125, 123, 124)
    private static let directionThreshold = 0.5

    // MARK: - Init

    public init(
        mouseSimulator: MouseSimulating,
        keySimulator: KeySimulating,
        actionDispatcher: ActionDispatching
    ) {
        self.mouseSimulator = mouseSimulator
        self.keySimulator = keySimulator
        self.actionDispatcher = actionDispatcher
    }

    // MARK: - Configuration

    /// Rebuild all processors from the active profile. Stops any running drivers first.
    public func configure(profile: Profile, globalConfig: GlobalConfig) {
        stop()

        sticks.removeAll()
        triggers.removeAll()
        axisToStick.removeAll()
        globalMouseConfig = globalConfig.mouse

        // Build stick processors and axis mapping
        for (stickName, stickConfig) in profile.sticks {
            guard stickConfig.mode != .disabled else { continue }

            sticks[stickName] = StickState(
                processor: StickProcessor(config: stickConfig),
                config: stickConfig
            )
            axisToStick["\(stickName) X Axis"] = (stickName, .x)
            axisToStick["\(stickName) Y Axis"] = (stickName, .y)
        }

        // Build trigger processors
        for (triggerName, triggerConfig) in profile.triggers {
            guard triggerConfig.mode != .disabled else { continue }

            triggers[triggerName] = TriggerState(
                processor: TriggerProcessor(config: triggerConfig),
                config: triggerConfig
            )
        }

        start(tickRate: globalConfig.input.pollRateHz)
    }

    // MARK: - Input Routing

    /// Attempt to handle an input as an analog stick or trigger.
    /// - Returns: `true` if the element was consumed by the analog pipeline (caller should skip digital binding lookup).
    public func handleInput(elementName: String, value: Float) -> Bool {
        // Check stick axes
        if let mapping = axisToStick[elementName] {
            updateStickAxis(stickName: mapping.stickName, axis: mapping.axis, value: value)
            return true
        }

        // Check triggers
        if triggers[elementName] != nil {
            updateTrigger(name: elementName, value: value)
            return true
        }

        return false
    }

    // MARK: - Lifecycle

    public func stop() {
        tickTimer?.invalidate()
        tickTimer = nil

        for (_, driver) in mouseDrivers {
            driver.stop()
        }
        mouseDrivers.removeAll()

        releaseAllDirectionKeys()
    }

    // MARK: - Private — Axis Updates

    private func updateStickAxis(stickName: String, axis: Axis, value: Float) {
        switch axis {
        case .x: sticks[stickName]?.lastRawX = value
        case .y: sticks[stickName]?.lastRawY = value
        }
    }

    private func updateTrigger(name: String, value: Float) {
        guard var state = triggers[name] else { return }

        let result = state.processor.process(rawValue: value)

        // Detect threshold crossing
        if result.isPressed && !state.wasPressed {
            if let action = state.config.action {
                do { try actionDispatcher.dispatch(action, pressed: true) }
                catch { logger.error("Trigger dispatch failed: \(error)") }
            }
        } else if !result.isPressed && state.wasPressed {
            if let action = state.config.action {
                do { try actionDispatcher.dispatch(action, pressed: false) }
                catch { logger.error("Trigger release failed: \(error)") }
            }
        }

        state.wasPressed = result.isPressed
        triggers[name] = state
    }

    // MARK: - Private — Tick Loop

    private func start(tickRate: Int) {
        tickInterval = 1.0 / Double(max(tickRate, 1))

        // Create MouseDrivers for mouse-mode sticks
        for (stickName, stickState) in sticks where stickState.config.mode == .mouse {
            let driver = MouseDriver(mouseSimulator: mouseSimulator)
            driver.sensitivity = stickState.config.sensitivity
            driver.maxSpeed = globalMouseConfig.maxSpeed * globalMouseConfig.globalSensitivity
            driver.start(tickRate: tickRate)
            mouseDrivers[stickName] = driver
        }

        // One tick timer for scroll / wasd / arrow modes
        let needsTick = sticks.values.contains { $0.config.mode == .scroll || $0.config.mode == .wasd || $0.config.mode == .arrows }
        if needsTick {
            tickTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
    }

    private func tick() {
        for (stickName, stickState) in sticks {
            let processed = stickState.processor.process(rawX: stickState.lastRawX, rawY: stickState.lastRawY)

            switch stickState.config.mode {
            case .mouse:
                // Feed processed values to MouseDriver (it has its own timer for movement)
                mouseDrivers[stickName]?.updateInput(x: processed.x, y: processed.y)

            case .scroll:
                guard abs(processed.x) > 0.001 || abs(processed.y) > 0.001 else { continue }
                let speed = stickState.config.scrollSpeed ?? 5.0
                let dx = processed.x * speed
                let dy = -processed.y * speed  // Invert Y for natural scroll direction
                do { try mouseSimulator.scroll(dx: dx, dy: dy) }
                catch { logger.error("Scroll failed: \(error)") }

            case .wasd:
                updateDirectionKeys(stickName: stickName, x: processed.x, y: processed.y, keys: Self.wasdKeys)

            case .arrows:
                updateDirectionKeys(stickName: stickName, x: processed.x, y: processed.y, keys: Self.arrowKeys)

            case .disabled:
                break
            }
        }
    }

    // MARK: - Private — Direction Key Management

    private func updateDirectionKeys(stickName: String, x: Double, y: Double, keys: (up: UInt16, down: UInt16, left: UInt16, right: UInt16)) {
        let threshold = Self.directionThreshold

        let wantUp    = y > threshold
        let wantDown  = y < -threshold
        let wantLeft  = x < -threshold
        let wantRight = x > threshold

        let currentlyHeld = sticks[stickName]?.heldKeys ?? []

        let desiredKeys: Set<UInt16> = {
            var set = Set<UInt16>()
            if wantUp    { set.insert(keys.up) }
            if wantDown  { set.insert(keys.down) }
            if wantLeft  { set.insert(keys.left) }
            if wantRight { set.insert(keys.right) }
            return set
        }()

        // Release keys no longer desired
        for code in currentlyHeld.subtracting(desiredKeys) {
            do { try keySimulator.releaseKey(code: code, flags: []) }
            catch { logger.error("Key release failed: \(error)") }
        }

        // Press newly desired keys
        for code in desiredKeys.subtracting(currentlyHeld) {
            do { try keySimulator.pressKey(code: code, flags: []) }
            catch { logger.error("Key press failed: \(error)") }
        }

        sticks[stickName]?.heldKeys = desiredKeys
    }

    private func releaseAllDirectionKeys() {
        for (stickName, stickState) in sticks {
            for code in stickState.heldKeys {
                do { try keySimulator.releaseKey(code: code, flags: []) }
                catch { logger.error("Key release failed: \(error)") }
            }
            sticks[stickName]?.heldKeys = []
        }
    }
}
