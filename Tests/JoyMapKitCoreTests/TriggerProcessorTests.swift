import XCTest
@testable import JoyMapKitCore

final class TriggerProcessorTests: XCTestCase {

    // MARK: - Digital mode

    func testDigitalModeBelowThresholdNotPressed() {
        let processor = makeProcessor(mode: .digital, threshold: 0.5)

        let result = processor.process(rawValue: 0.3)

        XCTAssertFalse(result.isPressed)
        XCTAssertEqual(result.analogValue, 0.3, accuracy: 0.001)
    }

    func testDigitalModeAtThresholdIsPressed() {
        let processor = makeProcessor(mode: .digital, threshold: 0.5)

        let result = processor.process(rawValue: 0.5)

        XCTAssertTrue(result.isPressed)
        XCTAssertEqual(result.analogValue, 0.5, accuracy: 0.001)
    }

    func testDigitalModeAboveThresholdIsPressed() {
        let processor = makeProcessor(mode: .digital, threshold: 0.5)

        let result = processor.process(rawValue: 0.8)

        XCTAssertTrue(result.isPressed)
        XCTAssertEqual(result.analogValue, 0.8, accuracy: 0.001)
    }

    func testDigitalModeZeroNotPressed() {
        let processor = makeProcessor(mode: .digital, threshold: 0.3)

        let result = processor.process(rawValue: 0.0)

        XCTAssertFalse(result.isPressed)
        XCTAssertEqual(result.analogValue, 0.0, accuracy: 0.001)
    }

    // MARK: - Analog mode

    func testAnalogModeAnyPositiveValueIsPressed() {
        let processor = makeProcessor(mode: .analog)

        let result = processor.process(rawValue: 0.01)

        XCTAssertTrue(result.isPressed)
        XCTAssertEqual(result.analogValue, 0.01, accuracy: 0.001)
    }

    func testAnalogModeZeroNotPressed() {
        let processor = makeProcessor(mode: .analog)

        let result = processor.process(rawValue: 0.0)

        XCTAssertFalse(result.isPressed)
        XCTAssertEqual(result.analogValue, 0.0, accuracy: 0.001)
    }

    func testAnalogModeFullDeflection() {
        let processor = makeProcessor(mode: .analog)

        let result = processor.process(rawValue: 1.0)

        XCTAssertTrue(result.isPressed)
        XCTAssertEqual(result.analogValue, 1.0, accuracy: 0.001)
    }

    // MARK: - MouseScroll mode

    func testMouseScrollModeBelowSmallThresholdNotPressed() {
        let processor = makeProcessor(mode: .mouseScroll)

        let result = processor.process(rawValue: 0.04)

        XCTAssertFalse(result.isPressed)
    }

    func testMouseScrollModeAboveSmallThresholdIsPressed() {
        let processor = makeProcessor(mode: .mouseScroll)

        let result = processor.process(rawValue: 0.1)

        XCTAssertTrue(result.isPressed)
        XCTAssertEqual(result.analogValue, 0.1, accuracy: 0.001)
    }

    // MARK: - Disabled mode

    func testDisabledModeAlwaysNotPressed() {
        let processor = makeProcessor(mode: .disabled)

        let result = processor.process(rawValue: 1.0)

        XCTAssertFalse(result.isPressed)
        XCTAssertEqual(result.analogValue, 0.0, accuracy: 0.001)
    }

    func testDisabledModeZeroValue() {
        let processor = makeProcessor(mode: .disabled)

        let result = processor.process(rawValue: 0.5)

        XCTAssertFalse(result.isPressed)
        XCTAssertEqual(result.analogValue, 0.0, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeProcessor(
        mode: TriggerConfig.TriggerMode = .digital,
        threshold: Double = 0.3
    ) -> TriggerProcessor {
        let config = TriggerConfig(mode: mode, threshold: threshold)
        return TriggerProcessor(config: config)
    }
}
