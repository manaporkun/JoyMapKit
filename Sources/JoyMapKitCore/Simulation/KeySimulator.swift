import Foundation
import CoreGraphics

/// Protocol for keyboard event simulation, enabling testability.
public protocol KeySimulating {
    func pressKey(code: UInt16, flags: CGEventFlags) throws
    func releaseKey(code: UInt16, flags: CGEventFlags) throws
    func tapKey(code: UInt16, flags: CGEventFlags, holdMs: Int?) throws
}

/// Simulates keyboard events using CGEvent.
public final class KeySimulator: KeySimulating {
    private let eventSource: CGEventSource?

    public init() {
        eventSource = CGEventSource(stateID: .hidSystemState)
    }

    public func pressKey(code: UInt16, flags: CGEventFlags = []) throws {
        guard let event = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(code), keyDown: true) else {
            throw SimulationError.eventCreationFailed
        }
        if !flags.isEmpty {
            event.flags = flags
        }
        event.post(tap: .cghidEventTap)
    }

    public func releaseKey(code: UInt16, flags: CGEventFlags = []) throws {
        guard let event = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(code), keyDown: false) else {
            throw SimulationError.eventCreationFailed
        }
        if !flags.isEmpty {
            event.flags = flags
        }
        event.post(tap: .cghidEventTap)
    }

    public func tapKey(code: UInt16, flags: CGEventFlags = [], holdMs: Int? = nil) throws {
        try pressKey(code: code, flags: flags)
        if let holdMs, holdMs > 0 {
            Thread.sleep(forTimeInterval: Double(holdMs) / 1000.0)
        }
        try releaseKey(code: code, flags: flags)
    }
}

/// Simulates mouse events using CGEvent.
public protocol MouseSimulating {
    func moveMouse(dx: Double, dy: Double) throws
    func click(button: ActionConfig.MouseClickAction.MouseButton, down: Bool) throws
    func scroll(dx: Double, dy: Double) throws
}

public final class MouseSimulator: MouseSimulating {
    private let eventSource: CGEventSource?

    public init() {
        eventSource = CGEventSource(stateID: .hidSystemState)
    }

    public func moveMouse(dx: Double, dy: Double) throws {
        guard let currentEvent = CGEvent(source: nil) else {
            throw SimulationError.eventCreationFailed
        }
        let currentPos = currentEvent.location
        let newPos = CGPoint(x: currentPos.x + dx, y: currentPos.y + dy)

        guard let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .mouseMoved,
            mouseCursorPosition: newPos,
            mouseButton: .left
        ) else {
            throw SimulationError.eventCreationFailed
        }
        event.post(tap: .cghidEventTap)
    }

    public func click(button: ActionConfig.MouseClickAction.MouseButton, down: Bool) throws {
        guard let currentEvent = CGEvent(source: nil) else {
            throw SimulationError.eventCreationFailed
        }
        let pos = currentEvent.location

        let (mouseType, mouseButton): (CGEventType, CGMouseButton) = switch button {
        case .left:   (down ? .leftMouseDown : .leftMouseUp, .left)
        case .right:  (down ? .rightMouseDown : .rightMouseUp, .right)
        case .middle: (down ? .otherMouseDown : .otherMouseUp, .center)
        }

        guard let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: mouseType,
            mouseCursorPosition: pos,
            mouseButton: mouseButton
        ) else {
            throw SimulationError.eventCreationFailed
        }
        event.post(tap: .cghidEventTap)
    }

    public func scroll(dx: Double, dy: Double) throws {
        guard let event = CGEvent(
            scrollWheelEvent2Source: eventSource,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(dy),
            wheel2: Int32(dx),
            wheel3: 0
        ) else {
            throw SimulationError.eventCreationFailed
        }
        event.post(tap: .cghidEventTap)
    }
}

public enum SimulationError: Error, CustomStringConvertible {
    case eventCreationFailed
    case accessibilityNotGranted

    public var description: String {
        switch self {
        case .eventCreationFailed:
            return "Failed to create CGEvent"
        case .accessibilityNotGranted:
            return "Accessibility permission not granted. Go to System Settings > Privacy & Security > Accessibility"
        }
    }
}
