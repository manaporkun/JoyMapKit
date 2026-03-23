import XCTest
@testable import JoyMapKitCore

final class MockActionDispatcher: ActionDispatching {
    var dispatchedActions: [(action: ActionConfig, pressed: Bool)] = []

    func dispatch(_ action: ActionConfig, pressed: Bool) throws {
        dispatchedActions.append((action: action, pressed: pressed))
    }
}

final class MappingEngineTests: XCTestCase {
    var engine: MappingEngine!
    var mockDispatcher: MockActionDispatcher!

    override func setUp() {
        super.setUp()
        mockDispatcher = MockActionDispatcher()
        engine = MappingEngine(actionDispatcher: mockDispatcher)
    }

    func testButtonPressDispatchesAction() {
        let profile = Profile(
            name: "test",
            bindings: [
                BindingConfig(
                    input: .single("Button A"),
                    action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
                ),
            ]
        )
        engine.setProfile(profile)

        let handle = makeMockHandle()

        // Press
        engine.handleInput(elementName: "Button A", value: 1.0, from: handle)
        XCTAssertEqual(mockDispatcher.dispatchedActions.count, 1)
        XCTAssertTrue(mockDispatcher.dispatchedActions[0].pressed)

        // Release
        engine.handleInput(elementName: "Button A", value: 0.0, from: handle)
        XCTAssertEqual(mockDispatcher.dispatchedActions.count, 2)
        XCTAssertFalse(mockDispatcher.dispatchedActions[1].pressed)
    }

    func testUnmappedButtonDoesNothing() {
        let profile = Profile(name: "test", bindings: [])
        engine.setProfile(profile)

        let handle = makeMockHandle()
        engine.handleInput(elementName: "Button B", value: 1.0, from: handle)
        XCTAssertTrue(mockDispatcher.dispatchedActions.isEmpty)
    }

    func testProfileSwitchReleasesHeldKeys() {
        let spaceAction = ActionConfig.keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        let profile1 = Profile(
            name: "test1",
            bindings: [
                BindingConfig(input: .single("Button A"), action: spaceAction),
            ]
        )
        let profile2 = Profile(name: "test2", bindings: [])

        engine.setProfile(profile1)

        let handle = makeMockHandle()
        engine.handleInput(elementName: "Button A", value: 1.0, from: handle)
        XCTAssertEqual(mockDispatcher.dispatchedActions.count, 1)

        // Switch profile — held key should be released
        engine.setProfile(profile2)
        XCTAssertEqual(mockDispatcher.dispatchedActions.count, 2)
        XCTAssertFalse(mockDispatcher.dispatchedActions[1].pressed)
    }

    func testNoProfileIgnoresInput() {
        let handle = makeMockHandle()
        engine.handleInput(elementName: "Button A", value: 1.0, from: handle)
        XCTAssertTrue(mockDispatcher.dispatchedActions.isEmpty)
    }

    // MARK: - Helpers

    private func makeMockHandle() -> ControllerHandle {
        ControllerHandle(vendorName: "Test Controller", controllerType: .generic)
    }
}
