import XCTest
@testable import JoyMapKitCore

final class ProfileCodingTests: XCTestCase {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private let decoder = JSONDecoder()

    // MARK: - Full profile round-trip

    func testProfileWithBindingsRoundTrips() throws {
        let id = UUID()
        let profile = Profile(
            id: id,
            name: "Gaming",
            version: 2,
            appBundleIDs: ["com.example.game"],
            bindings: [
                BindingConfig(
                    input: .single("Button A"),
                    action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
                ),
                BindingConfig(
                    input: .single("Button B"),
                    action: .mouseClick(ActionConfig.MouseClickAction(button: .left))
                ),
            ],
            sticks: [
                "leftStick": StickConfig(
                    mode: .mouse,
                    deadzone: 0.15,
                    outerDeadzone: 0.95,
                    responseCurve: ResponseCurveConfig(type: .quadratic),
                    sensitivity: 1.5
                ),
            ],
            triggers: [
                "leftTrigger": TriggerConfig(
                    mode: .digital,
                    threshold: 0.4,
                    action: .keyPress(ActionConfig.KeyPressAction(keyCode: 56, modifiers: [.shift], key: "Shift"))
                ),
            ]
        )

        let data = try encoder.encode(profile)
        let decoded = try decoder.decode(Profile.self, from: data)

        XCTAssertEqual(decoded.id, id)
        XCTAssertEqual(decoded.name, "Gaming")
        XCTAssertEqual(decoded.version, 2)
        XCTAssertEqual(decoded.appBundleIDs, ["com.example.game"])
        XCTAssertEqual(decoded.bindings.count, 2)
        XCTAssertEqual(decoded.sticks.count, 1)
        XCTAssertEqual(decoded.triggers.count, 1)
        XCTAssertEqual(decoded, profile)
    }

    // MARK: - BindingConfig with chord input

    func testBindingWithChordInputRoundTrips() throws {
        let binding = BindingConfig(
            input: .chord(["Button A", "Button B"]),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space")),
            holdBehavior: .onPress
        )

        let data = try encoder.encode(binding)
        let decoded = try decoder.decode(BindingConfig.self, from: data)

        XCTAssertEqual(decoded, binding)
        if case .chord(let elements) = decoded.input {
            XCTAssertEqual(elements, ["Button A", "Button B"])
        } else {
            XCTFail("Expected .chord input, got \(decoded.input)")
        }
    }

    func testBindingWithSequenceInputRoundTrips() throws {
        let binding = BindingConfig(
            input: .sequence(["Button A", "Button B"], timeoutMs: 500),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        )

        let data = try encoder.encode(binding)
        let decoded = try decoder.decode(BindingConfig.self, from: data)

        XCTAssertEqual(decoded, binding)
    }

    // MARK: - StickConfig with custom response curve

    func testStickConfigWithCustomCurveRoundTrips() throws {
        let stickConfig = StickConfig(
            mode: .mouse,
            deadzone: 0.1,
            outerDeadzone: 0.9,
            responseCurve: ResponseCurveConfig(
                type: .custom,
                customPoints: [[0.0, 0.0], [0.3, 0.1], [0.7, 0.9], [1.0, 1.0]]
            ),
            sensitivity: 2.0,
            scrollSpeed: 5.0
        )

        let data = try encoder.encode(stickConfig)
        let decoded = try decoder.decode(StickConfig.self, from: data)

        XCTAssertEqual(decoded, stickConfig)
        XCTAssertEqual(decoded.mode, .mouse)
        XCTAssertEqual(decoded.deadzone, 0.1, accuracy: 0.001)
        XCTAssertEqual(decoded.outerDeadzone, 0.9, accuracy: 0.001)
        XCTAssertEqual(decoded.sensitivity, 2.0, accuracy: 0.001)
        XCTAssertEqual(decoded.scrollSpeed, 5.0)
        XCTAssertEqual(decoded.responseCurve.type, .custom)
        XCTAssertEqual(decoded.responseCurve.customPoints?.count, 4)
    }

    func testStickConfigDefaultCurveRoundTrips() throws {
        let stickConfig = StickConfig()

        let data = try encoder.encode(stickConfig)
        let decoded = try decoder.decode(StickConfig.self, from: data)

        XCTAssertEqual(decoded, stickConfig)
        XCTAssertEqual(decoded.responseCurve.type, .linear)
        XCTAssertNil(decoded.responseCurve.customPoints)
    }

    // MARK: - TriggerConfig with action

    func testTriggerConfigWithActionRoundTrips() throws {
        let triggerConfig = TriggerConfig(
            mode: .digital,
            threshold: 0.5,
            action: .keyPress(ActionConfig.KeyPressAction(
                keyCode: 49,
                modifiers: [.command, .shift],
                key: "Space"
            ))
        )

        let data = try encoder.encode(triggerConfig)
        let decoded = try decoder.decode(TriggerConfig.self, from: data)

        XCTAssertEqual(decoded, triggerConfig)
        XCTAssertEqual(decoded.mode, .digital)
        XCTAssertEqual(decoded.threshold, 0.5, accuracy: 0.001)
        XCTAssertNotNil(decoded.action)
    }

    func testTriggerConfigWithoutActionRoundTrips() throws {
        let triggerConfig = TriggerConfig(mode: .analog, threshold: 0.0)

        let data = try encoder.encode(triggerConfig)
        let decoded = try decoder.decode(TriggerConfig.self, from: data)

        XCTAssertEqual(decoded, triggerConfig)
        XCTAssertNil(decoded.action)
    }

    func testTriggerConfigDisabledModeRoundTrips() throws {
        let triggerConfig = TriggerConfig(mode: .disabled, threshold: 0.3)

        let data = try encoder.encode(triggerConfig)
        let decoded = try decoder.decode(TriggerConfig.self, from: data)

        XCTAssertEqual(decoded, triggerConfig)
        XCTAssertEqual(decoded.mode, .disabled)
    }

    // MARK: - ActionConfig variants

    func testMouseClickActionRoundTrips() throws {
        let action = ActionConfig.mouseClick(ActionConfig.MouseClickAction(button: .right))

        let data = try encoder.encode(action)
        let decoded = try decoder.decode(ActionConfig.self, from: data)

        XCTAssertEqual(decoded, action)
    }

    func testScrollActionRoundTrips() throws {
        let action = ActionConfig.scroll(ActionConfig.ScrollAction(dx: 0.0, dy: -5.0))

        let data = try encoder.encode(action)
        let decoded = try decoder.decode(ActionConfig.self, from: data)

        XCTAssertEqual(decoded, action)
    }

    func testShellActionRoundTrips() throws {
        let action = ActionConfig.shell(ActionConfig.ShellAction(
            command: "/usr/bin/open",
            arguments: ["-a", "Safari"]
        ))

        let data = try encoder.encode(action)
        let decoded = try decoder.decode(ActionConfig.self, from: data)

        XCTAssertEqual(decoded, action)
    }

    func testProfileSwitchActionRoundTrips() throws {
        let action = ActionConfig.profileSwitch("FPS Profile")

        let data = try encoder.encode(action)
        let decoded = try decoder.decode(ActionConfig.self, from: data)

        XCTAssertEqual(decoded, action)
    }

    func testLayerToggleActionRoundTrips() throws {
        let action = ActionConfig.layerToggle("combat")

        let data = try encoder.encode(action)
        let decoded = try decoder.decode(ActionConfig.self, from: data)

        XCTAssertEqual(decoded, action)
    }

    func testNoneActionRoundTrips() throws {
        let action = ActionConfig.none

        let data = try encoder.encode(action)
        let decoded = try decoder.decode(ActionConfig.self, from: data)

        XCTAssertEqual(decoded, action)
    }

    // MARK: - HoldBehavior round-trips

    func testWhileHeldBehaviorRoundTrips() throws {
        let binding = BindingConfig(
            input: .single("Button A"),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space")),
            holdBehavior: .whileHeld(repeatIntervalMs: 100)
        )

        let data = try encoder.encode(binding)
        let decoded = try decoder.decode(BindingConfig.self, from: data)

        XCTAssertEqual(decoded, binding)
    }

    func testToggleHoldBehaviorRoundTrips() throws {
        let binding = BindingConfig(
            input: .single("Button A"),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space")),
            holdBehavior: .toggle
        )

        let data = try encoder.encode(binding)
        let decoded = try decoder.decode(BindingConfig.self, from: data)

        XCTAssertEqual(decoded, binding)
    }

    // MARK: - Layer config

    func testProfileWithLayersRoundTrips() throws {
        let profile = Profile(
            name: "Layered",
            bindings: [],
            layers: [
                LayerConfig(
                    name: "combat",
                    activator: .single("Left Shoulder"),
                    bindings: [
                        BindingConfig(
                            input: .single("Button A"),
                            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space")),
                            layer: "combat"
                        ),
                    ]
                ),
            ]
        )

        let data = try encoder.encode(profile)
        let decoded = try decoder.decode(Profile.self, from: data)

        XCTAssertEqual(decoded.layers.count, 1)
        XCTAssertEqual(decoded.layers[0].name, "combat")
        XCTAssertEqual(decoded.layers[0].bindings.count, 1)
        XCTAssertEqual(decoded.layers[0].bindings[0].layer, "combat")
        XCTAssertEqual(decoded, profile)
    }

    // MARK: - Deterministic encoding

    func testEncodingIsDeterministic() throws {
        let profile = Profile(
            name: "Deterministic",
            bindings: [
                BindingConfig(
                    input: .single("Button A"),
                    action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
                ),
            ]
        )

        let data1 = try encoder.encode(profile)
        let data2 = try encoder.encode(profile)

        XCTAssertEqual(data1, data2, "Encoding with .sortedKeys should produce identical output")
    }
}
