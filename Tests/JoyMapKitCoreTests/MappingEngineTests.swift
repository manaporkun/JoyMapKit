import XCTest
@testable import JoyMapKitCore

final class MockActionDispatcher: ActionDispatching {
    var dispatchedActions: [(action: ActionConfig, pressed: Bool)] = []
    var onMacro: ((_ macro: ActionConfig.MacroAction, _ key: String, _ pressed: Bool) -> Void)?
    var onProfileSwitch: ((_ profileName: String) -> Void)?
    var onLayerToggle: ((_ layerName: String) -> Void)?

    func dispatch(_ action: ActionConfig, pressed: Bool) throws {
        dispatchedActions.append((action: action, pressed: pressed))

        switch action {
        case .macro(let macro):
            onMacro?(macro, macro.name ?? UUID().uuidString, pressed)
        case .profileSwitch(let profileName) where pressed:
            onProfileSwitch?(profileName)
        case .layerToggle(let layerName) where pressed:
            onLayerToggle?(layerName)
        default:
            break
        }
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

    func testProfileSwitchActionInvokesCallback() {
        let profile = Profile(
            name: "test",
            bindings: [
                BindingConfig(
                    input: .single("Button A"),
                    action: .profileSwitch("alternate")
                ),
            ]
        )
        engine.setProfile(profile)

        let expectation = expectation(description: "profile switch callback")
        var switchedProfile: String?
        engine.onProfileSwitchRequested = { name in
            switchedProfile = name
            expectation.fulfill()
        }

        let handle = makeMockHandle()
        engine.handleInput(elementName: "Button A", value: 1.0, from: handle)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(switchedProfile, "alternate")
    }

    func testMostRecentlyActivatedLayerWins() {
        let baseAction = ActionConfig.keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        let combatAction = ActionConfig.keyPress(ActionConfig.KeyPressAction(keyCode: 36, key: "Return"))
        let menuAction = ActionConfig.keyPress(ActionConfig.KeyPressAction(keyCode: 53, key: "Escape"))
        let profile = Profile(
            name: "test",
            bindings: [
                BindingConfig(input: .single("Button X"), action: baseAction),
            ],
            layers: [
                LayerConfig(
                    name: "combat",
                    activator: .single("Left Shoulder"),
                    bindings: [
                        BindingConfig(input: .single("Button X"), action: combatAction),
                    ]
                ),
                LayerConfig(
                    name: "menu",
                    activator: .single("Right Shoulder"),
                    bindings: [
                        BindingConfig(input: .single("Button X"), action: menuAction),
                    ]
                ),
            ]
        )
        engine.setProfile(profile)

        let handle = makeMockHandle()
        engine.handleInput(elementName: "Left Shoulder", value: 1.0, from: handle)
        engine.handleInput(elementName: "Right Shoulder", value: 1.0, from: handle)
        engine.handleInput(elementName: "Button X", value: 1.0, from: handle)

        XCTAssertEqual(mockDispatcher.dispatchedActions.last?.action, menuAction)
        XCTAssertEqual(mockDispatcher.dispatchedActions.last?.pressed, true)
    }

    // MARK: - Helpers

    private func makeMockHandle() -> ControllerHandle {
        ControllerHandle(vendorName: "Test Controller", controllerType: .generic)
    }
}
