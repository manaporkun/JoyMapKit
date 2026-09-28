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

    func pressKey(code: UInt16, flags: CGEventFlags) throws {
        events.append(.press(code, flags.rawValue))
    }

    func releaseKey(code: UInt16, flags: CGEventFlags) throws {
        events.append(.release(code, flags.rawValue))
    }

    func tapKey(code: UInt16, flags: CGEventFlags, holdMs: Int?) throws {
        try pressKey(code: code, flags: flags)
        try releaseKey(code: code, flags: flags)
    }

    func modifierChanged(code: UInt16, flags: CGEventFlags) throws {
        events.append(.modifier(code, flags.rawValue))
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
}
