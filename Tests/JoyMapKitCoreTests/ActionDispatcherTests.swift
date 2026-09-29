import XCTest
import CoreGraphics
@testable import JoyMapKitCore

final class MockKeySimulator: KeySimulating {
    enum Event: Equatable {
        case press(UInt16, CGEventFlags.RawValue)
        case release(UInt16, CGEventFlags.RawValue)
        case modifier(UInt16, CGEventFlags.RawValue)
    }

    var events: [Event] = []
    var onEvent: ((Event) -> Void)?
    var modifierChangeError: Error?

    func pressKey(code: UInt16, flags: CGEventFlags) throws {
        record(.press(code, flags.rawValue))
    }

    func releaseKey(code: UInt16, flags: CGEventFlags) throws {
        record(.release(code, flags.rawValue))
    }

    func tapKey(code: UInt16, flags: CGEventFlags, holdMs: Int?) throws {
        try pressKey(code: code, flags: flags)
        try releaseKey(code: code, flags: flags)
    }

    func modifierChanged(code: UInt16, flags: CGEventFlags) throws {
        if let modifierChangeError { throw modifierChangeError }
        record(.modifier(code, flags.rawValue))
    }

    private func record(_ event: Event) {
        events.append(event)
        onEvent?(event)
    }
}

final class MockMouseSimulator: MouseSimulating {
    func moveMouse(dx: Double, dy: Double) throws {}
    func click(button: ActionConfig.MouseClickAction.MouseButton, down: Bool) throws {}
    func scroll(dx: Double, dy: Double) throws {}
}

final class ActionDispatcherTests: XCTestCase {
    var keySimulator: MockKeySimulator!
    var dispatcher: ActionDispatcher!

    let command = ActionConfig.keyPress(.init(keyCode: 55, key: "Command"))
    let shift = ActionConfig.keyPress(.init(keyCode: 56, key: "Shift"))
    let leftArrow = ActionConfig.keyPress(.init(keyCode: 123, key: "Left Arrow"))

    override func setUp() {
        super.setUp()
        keySimulator = MockKeySimulator()
        dispatcher = ActionDispatcher(keySimulator: keySimulator, mouseSimulator: MockMouseSimulator())
    }

    func testBareModifierPostsFlagsChanged() throws {
        try dispatcher.dispatch(command, pressed: true)
        try dispatcher.dispatch(command, pressed: false)

        XCTAssertEqual(keySimulator.events, [
            .modifier(55, CGEventFlags.maskCommand.rawValue),
            .modifier(55, 0),
        ])
    }

    func testHeldModifiersCombineIntoKeyPress() throws {
        let both = CGEventFlags([.maskCommand, .maskShift]).rawValue

        try dispatcher.dispatch(command, pressed: true)
        try dispatcher.dispatch(shift, pressed: true)
        try dispatcher.dispatch(leftArrow, pressed: true)
        try dispatcher.dispatch(leftArrow, pressed: false)

        XCTAssertEqual(keySimulator.events.suffix(2), [
            .press(123, both),
            .release(123, both),
        ])
    }

    func testReleasedModifierNoLongerApplied() throws {
        try dispatcher.dispatch(command, pressed: true)
        try dispatcher.dispatch(command, pressed: false)
        try dispatcher.dispatch(leftArrow, pressed: true)

        XCTAssertEqual(keySimulator.events.last, .press(123, 0))
    }

    func testHeldModifierMergesWithBindingModifiers() throws {
        let optionLeft = ActionConfig.keyPress(.init(keyCode: 123, modifiers: [.option], key: "Opt+Left"))

        try dispatcher.dispatch(shift, pressed: true)
        try dispatcher.dispatch(optionLeft, pressed: true)

        XCTAssertEqual(
            keySimulator.events.last,
            .press(123, CGEventFlags([.maskShift, .maskAlternate]).rawValue)
        )
    }

    func testTwoBindingsForSameModifierShareFirstPressAndFinalRelease() throws {
        try dispatcher.dispatch(command, pressed: true)
        try dispatcher.dispatch(command, pressed: true)
        try dispatcher.dispatch(command, pressed: false)
        try dispatcher.dispatch(leftArrow, pressed: true)
        try dispatcher.dispatch(command, pressed: false)
        try dispatcher.dispatch(command, pressed: false) // Unmatched cleanup is harmless.
        try dispatcher.dispatch(leftArrow, pressed: true)

        XCTAssertEqual(keySimulator.events, [
            .modifier(55, CGEventFlags.maskCommand.rawValue),
            .press(123, CGEventFlags.maskCommand.rawValue),
            .modifier(55, 0),
            .press(123, 0),
        ])
    }

    func testReleasingLeftCommandPreservesRightCommand() throws {
        let rightCommand = ActionConfig.keyPress(.init(keyCode: 54))
        try dispatcher.dispatch(command, pressed: true)
        try dispatcher.dispatch(rightCommand, pressed: true)
        try dispatcher.dispatch(command, pressed: false)
        try dispatcher.dispatch(leftArrow, pressed: true)
        XCTAssertEqual(keySimulator.events.last, .press(123, CGEventFlags.maskCommand.rawValue))

        try dispatcher.dispatch(rightCommand, pressed: false)
        try dispatcher.dispatch(leftArrow, pressed: true)
        XCTAssertEqual(keySimulator.events.last, .press(123, 0))
    }

    func testModifierKeyWithExplicitModifiersKeepsConfiguredFlags() throws {
        let commandShift = ActionConfig.keyPress(.init(keyCode: 56, modifiers: [.command, .shift]))
        let option = ActionConfig.keyPress(.init(keyCode: 58))
        try dispatcher.dispatch(option, pressed: true)
        try dispatcher.dispatch(commandShift, pressed: true)
        try dispatcher.dispatch(commandShift, pressed: false)
        let combined = CGEventFlags([.maskCommand, .maskShift, .maskAlternate]).rawValue
        XCTAssertEqual(keySimulator.events.suffix(2), [.press(56, combined), .release(56, combined)])

        try dispatcher.dispatch(leftArrow, pressed: true)
        XCTAssertEqual(keySimulator.events.last, .press(123, CGEventFlags.maskAlternate.rawValue))
    }

    func testFailedModifierEventDoesNotChangeHeldState() throws {
        keySimulator.modifierChangeError = SimulationError.eventCreationFailed
        XCTAssertThrowsError(try dispatcher.dispatch(command, pressed: true))
        keySimulator.modifierChangeError = nil
        try dispatcher.dispatch(leftArrow, pressed: true)
        XCTAssertEqual(keySimulator.events.last, .press(123, 0))

        try dispatcher.dispatch(command, pressed: true)
        keySimulator.modifierChangeError = SimulationError.eventCreationFailed
        XCTAssertThrowsError(try dispatcher.dispatch(command, pressed: false))
        keySimulator.modifierChangeError = nil
        try dispatcher.dispatch(command, pressed: false)
        try dispatcher.dispatch(leftArrow, pressed: true)
        XCTAssertEqual(keySimulator.events.last, .press(123, 0))
    }
}
