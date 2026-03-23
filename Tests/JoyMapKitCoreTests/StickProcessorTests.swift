import XCTest
@testable import JoyMapKitCore

final class StickProcessorTests: XCTestCase {

    // MARK: - Deadzone

    func testInputWithinDeadzoneReturnsZero() {
        let processor = makeProcessor(deadzone: 0.2)

        let result = processor.process(rawX: 0.1, rawY: 0.0)

        XCTAssertEqual(result.x, 0.0, accuracy: 0.001)
        XCTAssertEqual(result.y, 0.0, accuracy: 0.001)
    }

    func testInputExactlyAtDeadzoneReturnsZero() {
        let processor = makeProcessor(deadzone: 0.2)

        // Magnitude = 0.2 exactly, guard uses >, so 0.2 is NOT greater than 0.2
        let result = processor.process(rawX: 0.2, rawY: 0.0)

        XCTAssertEqual(result.x, 0.0, accuracy: 0.001)
        XCTAssertEqual(result.y, 0.0, accuracy: 0.001)
    }

    func testInputJustOutsideDeadzoneReturnsNonZero() {
        let processor = makeProcessor(deadzone: 0.2)

        let result = processor.process(rawX: 0.25, rawY: 0.0)

        XCTAssertGreaterThan(abs(result.x), 0.0)
    }

    // MARK: - Circular deadzone

    func testDiagonalInputWithinCircularDeadzoneReturnsZero() {
        let processor = makeProcessor(deadzone: 0.2)

        // Diagonal input: magnitude = sqrt(0.1^2 + 0.1^2) = ~0.141, which is < 0.2
        let result = processor.process(rawX: 0.1, rawY: 0.1)

        XCTAssertEqual(result.x, 0.0, accuracy: 0.001)
        XCTAssertEqual(result.y, 0.0, accuracy: 0.001)
    }

    func testDiagonalInputOutsideCircularDeadzoneReturnsNonZero() {
        let processor = makeProcessor(deadzone: 0.2)

        // Diagonal: magnitude = sqrt(0.2^2 + 0.2^2) = ~0.283, which is > 0.2
        let result = processor.process(rawX: 0.2, rawY: 0.2)

        XCTAssertGreaterThan(abs(result.x), 0.0)
        XCTAssertGreaterThan(abs(result.y), 0.0)
    }

    // MARK: - Full deflection

    func testFullDeflectionWithLinearCurveReturnsSensitivity() {
        let sensitivity = 1.5
        let processor = makeProcessor(
            deadzone: 0.0,
            outerDeadzone: 1.0,
            curve: .linear,
            sensitivity: sensitivity
        )

        let result = processor.process(rawX: 1.0, rawY: 0.0)

        // With deadzone=0, outerDeadzone=1, linear curve: normalized=1, curved=1, final=sensitivity
        XCTAssertEqual(result.x, sensitivity, accuracy: 0.001)
        XCTAssertEqual(result.y, 0.0, accuracy: 0.001)
    }

    func testFullDeflectionYAxis() {
        let processor = makeProcessor(
            deadzone: 0.0,
            outerDeadzone: 1.0,
            curve: .linear,
            sensitivity: 1.0
        )

        let result = processor.process(rawX: 0.0, rawY: 1.0)

        XCTAssertEqual(result.x, 0.0, accuracy: 0.001)
        XCTAssertEqual(result.y, 1.0, accuracy: 0.001)
    }

    // MARK: - Response curve effect

    func testQuadraticCurveReducesSmallInputsMoreThanLargeOnes() {
        let linearProcessor = makeProcessor(
            deadzone: 0.0,
            outerDeadzone: 1.0,
            curve: .linear,
            sensitivity: 1.0
        )
        let quadProcessor = makeProcessor(
            deadzone: 0.0,
            outerDeadzone: 1.0,
            curve: .quadratic,
            sensitivity: 1.0
        )

        // Small input
        let linearSmall = linearProcessor.process(rawX: 0.3, rawY: 0.0)
        let quadSmall = quadProcessor.process(rawX: 0.3, rawY: 0.0)

        // Quadratic should produce smaller output for small inputs
        XCTAssertLessThan(abs(quadSmall.x), abs(linearSmall.x))

        // Large input
        let linearLarge = linearProcessor.process(rawX: 0.9, rawY: 0.0)
        let quadLarge = quadProcessor.process(rawX: 0.9, rawY: 0.0)

        // The ratio difference should be smaller for large inputs
        let smallRatio = abs(quadSmall.x) / abs(linearSmall.x)
        let largeRatio = abs(quadLarge.x) / abs(linearLarge.x)
        XCTAssertLessThan(smallRatio, largeRatio)
    }

    // MARK: - Outer deadzone clamping

    func testOuterDeadzoneClampsMaxOutput() {
        let processor = makeProcessor(
            deadzone: 0.0,
            outerDeadzone: 0.8,
            curve: .linear,
            sensitivity: 1.0
        )

        // Input at 1.0 should be clamped to outerDeadzone, then normalized to 1.0
        let atMax = processor.process(rawX: 1.0, rawY: 0.0)
        let atOuter = processor.process(rawX: 0.8, rawY: 0.0)

        XCTAssertEqual(atMax.x, atOuter.x, accuracy: 0.001)
    }

    // MARK: - Zero input

    func testZeroInputReturnsZero() {
        let processor = makeProcessor(deadzone: 0.15)

        let result = processor.process(rawX: 0.0, rawY: 0.0)

        XCTAssertEqual(result.x, 0.0, accuracy: 0.001)
        XCTAssertEqual(result.y, 0.0, accuracy: 0.001)
    }

    // MARK: - Negative input

    func testNegativeInputPreservesDirection() {
        let processor = makeProcessor(
            deadzone: 0.0,
            outerDeadzone: 1.0,
            curve: .linear,
            sensitivity: 1.0
        )

        let result = processor.process(rawX: -1.0, rawY: 0.0)

        XCTAssertEqual(result.x, -1.0, accuracy: 0.001)
        XCTAssertEqual(result.y, 0.0, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeProcessor(
        deadzone: Double = 0.15,
        outerDeadzone: Double = 0.95,
        curve: ResponseCurveConfig.ResponseCurveType = .linear,
        sensitivity: Double = 1.0
    ) -> StickProcessor {
        let config = StickConfig(
            mode: .mouse,
            deadzone: deadzone,
            outerDeadzone: outerDeadzone,
            responseCurve: ResponseCurveConfig(type: curve),
            sensitivity: sensitivity
        )
        return StickProcessor(config: config)
    }
}
