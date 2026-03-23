import XCTest
@testable import JoyMapKitCore

final class ChordDetectorTests: XCTestCase {
    var detector: ChordDetector!

    override func setUp() {
        super.setUp()
        detector = ChordDetector(chordWindowMs: 50)
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    // MARK: - Non-chord elements

    func testNonChordElementReturnsImmediate() {
        let chordBinding = BindingConfig(
            input: .chord(["Button A", "Button B"]),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        )
        detector.configure(bindings: [chordBinding])

        let result = detector.handlePress("Button X")

        if case .immediate = result {
            // Expected
        } else {
            XCTFail("Expected .immediate for non-chord element, got \(result)")
        }
    }

    func testElementNotInAnyChordReturnsImmediate() {
        // No chord bindings at all
        let singleBinding = BindingConfig(
            input: .single("Button A"),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        )
        detector.configure(bindings: [singleBinding])

        let result = detector.handlePress("Button A")

        if case .immediate = result {
            // Expected
        } else {
            XCTFail("Expected .immediate when no chord bindings exist, got \(result)")
        }
    }

    // MARK: - Chord participant returns deferred

    func testChordParticipantReturnsDeferredOnFirstPress() {
        let chordBinding = BindingConfig(
            input: .chord(["Button A", "Button B"]),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        )
        detector.configure(bindings: [chordBinding])

        let result = detector.handlePress("Button A")

        if case .deferred = result {
            // Expected
        } else {
            XCTFail("Expected .deferred for chord participant, got \(result)")
        }
    }

    // MARK: - Chord completion

    func testAllChordMembersPressedReturnsChordMatched() {
        let chordAction = ActionConfig.keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        let chordBinding = BindingConfig(
            input: .chord(["Button A", "Button B"]),
            action: chordAction
        )
        detector.configure(bindings: [chordBinding])

        _ = detector.handlePress("Button A")
        let result = detector.handlePress("Button B")

        if case .chordMatched(let binding, let elements) = result {
            XCTAssertEqual(binding.action, chordAction)
            XCTAssertTrue(elements.contains("Button A"))
            XCTAssertTrue(elements.contains("Button B"))
            XCTAssertEqual(elements.count, 2)
        } else {
            XCTFail("Expected .chordMatched, got \(result)")
        }
    }

    func testChordMatchedInReverseOrder() {
        let chordAction = ActionConfig.keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        let chordBinding = BindingConfig(
            input: .chord(["Button A", "Button B"]),
            action: chordAction
        )
        detector.configure(bindings: [chordBinding])

        _ = detector.handlePress("Button B")
        let result = detector.handlePress("Button A")

        if case .chordMatched(_, let elements) = result {
            XCTAssertTrue(elements.contains("Button A"))
            XCTAssertTrue(elements.contains("Button B"))
        } else {
            XCTFail("Expected .chordMatched regardless of press order, got \(result)")
        }
    }

    // MARK: - Window expiry fires deferred callback

    func testWindowExpiryFiresOnDeferredPress() {
        let chordBinding = BindingConfig(
            input: .chord(["Button A", "Button B"]),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        )
        detector.configure(bindings: [chordBinding])

        let expectation = expectation(description: "Deferred press callback fired")
        var deferredElement: String?

        detector.onDeferredPress = { element in
            deferredElement = element
            expectation.fulfill()
        }

        _ = detector.handlePress("Button A")

        // Wait for chord window to expire (50ms + buffer)
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(deferredElement, "Button A")
    }

    // MARK: - Reset

    func testResetClearsState() {
        let chordBinding = BindingConfig(
            input: .chord(["Button A", "Button B"]),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        )
        detector.configure(bindings: [chordBinding])

        _ = detector.handlePress("Button A")
        detector.reset()

        // After reset, pressing Button B alone should return deferred (not chordMatched)
        // because Button A's press state was cleared
        let result = detector.handlePress("Button B")

        if case .deferred = result {
            // Expected: chord not completed because Button A state was cleared
        } else {
            XCTFail("Expected .deferred after reset, got \(result)")
        }
    }

    // MARK: - Release

    func testReleaseRemovesFromPressedSet() {
        let chordBinding = BindingConfig(
            input: .chord(["Button A", "Button B"]),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        )
        detector.configure(bindings: [chordBinding])

        _ = detector.handlePress("Button A")
        detector.handleRelease("Button A")

        // Now pressing Button B should be deferred (not chordMatched)
        let result = detector.handlePress("Button B")

        if case .deferred = result {
            // Expected
        } else {
            XCTFail("Expected .deferred after Button A was released, got \(result)")
        }
    }

    // MARK: - Configure replaces previous state

    func testConfigureResetsChordBindings() {
        let binding1 = BindingConfig(
            input: .chord(["Button A", "Button B"]),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        )
        detector.configure(bindings: [binding1])

        // Reconfigure with no chord bindings
        let binding2 = BindingConfig(
            input: .single("Button A"),
            action: .keyPress(ActionConfig.KeyPressAction(keyCode: 49, key: "Space"))
        )
        detector.configure(bindings: [binding2])

        // Button A should now be immediate since there are no chord bindings
        let result = detector.handlePress("Button A")

        if case .immediate = result {
            // Expected
        } else {
            XCTFail("Expected .immediate after reconfiguring without chords, got \(result)")
        }
    }
}
