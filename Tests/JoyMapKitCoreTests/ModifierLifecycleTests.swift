import XCTest
import CoreGraphics
@testable import JoyMapKitCore

final class ModifierLifecycleTests: XCTestCase {
    private var keys: MockKeySimulator!
    private var dispatcher: ActionDispatcher!
    private var engine: MappingEngine!
    private var analog: AnalogHandler!
    private let controller = ControllerHandle(vendorName: "Test", controllerType: .generic)
    private let command = ActionConfig.keyPress(.init(keyCode: 55))
    private let arrow = ActionConfig.keyPress(.init(keyCode: 123))

    override func setUp() {
        super.setUp()
        keys = MockKeySimulator()
        let mouse = MockMouseSimulator()
        dispatcher = ActionDispatcher(keySimulator: keys, mouseSimulator: mouse)
        engine = MappingEngine(actionDispatcher: dispatcher)
        analog = AnalogHandler(mouseSimulator: mouse, keySimulator: keys, actionDispatcher: dispatcher)
        engine.analogHandler = analog
    }

    override func tearDown() {
        keys.onEvent = nil
        analog.stop()
        engine.releaseAllHeldKeys()
        super.tearDown()
    }

    private func activate(_ profile: Profile) {
        engine.setProfile(profile)
        analog.configure(profile: profile, globalConfig: GlobalConfig())
    }

    private func input(_ element: String, _ value: Float) {
        engine.handleInput(elementName: element, value: value, from: controller)
    }

    private func assertArrowFlags(_ flags: CGEventFlags, file: StaticString = #filePath, line: UInt = #line) throws {
        try dispatcher.dispatch(arrow, pressed: true)
        XCTAssertEqual(keys.events.last, .press(123, flags.rawValue), file: file, line: line)
    }

    func testProfileSwitchReleasesTriggerModifierBeforeNextShortcut() {
        activate(Profile(name: "old", triggers: ["Right Trigger": TriggerConfig(action: command)]))
        input("Right Trigger", 1)
        activate(Profile(name: "new", bindings: [
            BindingConfig(input: .single("Button A"), action: .keyPress(.init(keyCode: 123, modifiers: [.option])))
        ], triggers: ["Right Trigger": TriggerConfig(action: .mouseClick(.init(button: .left)))]))
        input("Right Trigger", 0)
        input("Button A", 1)
        XCTAssertEqual(keys.events.last, .press(123, CGEventFlags.maskAlternate.rawValue))
    }

    func testStoppingTwiceReleasesTriggerOnlyOnce() throws {
        activate(Profile(name: "test", triggers: ["Right Trigger": TriggerConfig(action: command)]))
        try dispatcher.dispatch(command, pressed: true)
        input("Right Trigger", 1)
        analog.stop()
        analog.stop()
        try assertArrowFlags(.maskCommand)
        try dispatcher.dispatch(command, pressed: false)
        try assertArrowFlags([])
    }

    func testDisconnectCleanupAllowsTriggerToBePressedAgain() throws {
        activate(Profile(name: "test", triggers: ["Right Trigger": TriggerConfig(action: command)]))
        input("Right Trigger", 1)
        analog.releaseAllHeldInputs()
        engine.releaseAllHeldKeys()
        try assertArrowFlags([])
        input("Right Trigger", 1)
        try assertArrowFlags(.maskCommand)
        input("Right Trigger", 0)
        try assertArrowFlags([])
    }

    func testCleanupCancelsPendingChordParticipantPress() throws {
        activate(Profile(name: "test", bindings: [
            BindingConfig(input: .single("Button A"), action: command),
            BindingConfig(input: .chord(["Button A", "Button B"]), action: .none)
        ]))
        input("Button A", 1)
        engine.releaseAllHeldKeys()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        XCTAssertTrue(keys.events.isEmpty)
        try assertArrowFlags([])
    }

    func testDisconnectCleanupClearsStickStateWithoutStoppingTicks() {
        activate(Profile(name: "test", sticks: ["Left Thumbstick": StickConfig(mode: .arrows)]))
        input("Left Thumbstick X Axis", -1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(keys.events.last, .press(123, 0))
        keys.events.removeAll()
        analog.releaseAllHeldInputs()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(keys.events, [.release(123, 0)])
        input("Left Thumbstick X Axis", -1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(keys.events.last, .press(123, 0))
    }

    func testTriggerProfileSwitchDoesNotRestoreOldTriggerState() throws {
        let next = Profile(name: "next", triggers: ["Right Trigger": TriggerConfig(action: command)])
        engine.onProfileSwitchRequested = { [weak self] _ in self?.activate(next) }
        activate(Profile(name: "first", triggers: ["Right Trigger": TriggerConfig(action: .profileSwitch("next"))]))
        input("Right Trigger", 1)
        input("Right Trigger", 0)
        input("Right Trigger", 1)
        try assertArrowFlags(.maskCommand)
    }

    func testChordCleanupPreservesModifierHeldByTrigger() throws {
        activate(Profile(name: "test", bindings: [
            BindingConfig(input: .chord(["Button A", "Button B"]), action: command)
        ], triggers: ["Right Trigger": TriggerConfig(action: command)]))
        input("Right Trigger", 1)
        input("Button A", 1)
        input("Button B", 1)
        engine.releaseAllHeldKeys()
        engine.releaseAllHeldKeys()
        try assertArrowFlags(.maskCommand)
        analog.releaseAllHeldInputs()
        try assertArrowFlags([])
    }

    func testRepeatedChordPressDoesNotLeaveModifierHeld() throws {
        activate(Profile(name: "test", bindings: [
            BindingConfig(input: .chord(["Button A", "Button B"]), action: command)
        ]))
        input("Button A", 1)
        input("Button B", 1)
        input("Button B", 1)
        input("Button B", 0)
        try assertArrowFlags([])
    }

    func testLargerChordReleasesReplacedChordActivation() throws {
        activate(Profile(name: "test", bindings: [
            BindingConfig(input: .chord(["Button A", "Button B"]), action: command),
            BindingConfig(input: .chord(["Button A", "Button B", "Button X"]), action: command)
        ]))
        input("Button A", 1)
        input("Button B", 1)
        input("Button X", 1)
        input("Button X", 0)
        try assertArrowFlags([])
    }

    func testCleanupDoesNotReleaseAnOnReleaseBindingThatNeverPressed() throws {
        activate(Profile(name: "test", bindings: [
            BindingConfig(input: .single("Button A"), action: command, holdBehavior: .onRelease)
        ]))
        try dispatcher.dispatch(command, pressed: true)
        input("Button A", 1)
        engine.releaseAllHeldKeys()
        try assertArrowFlags(.maskCommand)
        try dispatcher.dispatch(command, pressed: false)
    }

    func testRepeatedTurboInputDoesNotLeaveModifierHeld() throws {
        activate(Profile(name: "test", bindings: [
            BindingConfig(input: .single("Button A"), action: command)
        ], turboButton: "Button Menu"))
        input("Button Menu", 1)
        input("Button A", 1)
        input("Button Menu", 0)
        input("Button A", 0)
        input("Button A", 1)
        input("Button A", 0.8)
        input("Button A", 0)
        try assertArrowFlags([])
    }

    @MainActor
    func testProfileSwitchSynchronouslyReleasesHeldMacroStep() async throws {
        let pressed = expectation(description: "macro presses Command")
        keys.onEvent = { event in
            if event == .modifier(55, CGEventFlags.maskCommand.rawValue) { pressed.fulfill() }
        }
        let macro = ActionConfig.macro(.init(name: "hold-command", steps: [
            .init(action: command, holdMs: 10_000)
        ]))
        activate(Profile(name: "test", bindings: [BindingConfig(input: .single("Button A"), action: macro)]))
        input("Button A", 1)
        await fulfillment(of: [pressed], timeout: 1)
        activate(Profile(name: "next"))
        try assertArrowFlags([])
    }

    @MainActor
    func testReplacingMacroKeepsReplacementCancellable() async throws {
        let commandPressed = expectation(description: "first macro presses Command")
        let shiftPressed = expectation(description: "replacement macro presses Shift")
        keys.onEvent = { event in
            if event == .modifier(55, CGEventFlags.maskCommand.rawValue) { commandPressed.fulfill() }
            if event == .modifier(56, CGEventFlags.maskShift.rawValue) { shiftPressed.fulfill() }
        }
        let runner = MacroRunner(actionDispatcher: dispatcher)
        defer { runner.cancelAll() }
        runner.start(.init(steps: [.init(action: command, holdMs: 10_000)]), key: "macro")
        await fulfillment(of: [commandPressed], timeout: 1)
        runner.start(.init(steps: [.init(action: .keyPress(.init(keyCode: 56)), holdMs: 10_000)]), key: "macro")
        await fulfillment(of: [shiftPressed], timeout: 1)
        runner.cancel(key: "macro")
        try assertArrowFlags([])
    }
}
