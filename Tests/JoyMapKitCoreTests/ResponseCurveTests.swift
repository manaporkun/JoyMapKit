import XCTest
@testable import JoyMapKitCore

final class ResponseCurveTests: XCTestCase {

    // MARK: - Linear

    func testLinearHalfInput() {
        let curve = ResponseCurve.linear

        XCTAssertEqual(curve.apply(0.5), 0.5, accuracy: 0.001)
    }

    func testLinearFullInput() {
        let curve = ResponseCurve.linear

        XCTAssertEqual(curve.apply(1.0), 1.0, accuracy: 0.001)
    }

    func testLinearZeroInput() {
        let curve = ResponseCurve.linear

        XCTAssertEqual(curve.apply(0.0), 0.0, accuracy: 0.001)
    }

    // MARK: - Quadratic

    func testQuadraticHalfInput() {
        let curve = ResponseCurve.quadratic

        // 0.5^2 = 0.25
        XCTAssertEqual(curve.apply(0.5), 0.25, accuracy: 0.001)
    }

    func testQuadraticFullInput() {
        let curve = ResponseCurve.quadratic

        XCTAssertEqual(curve.apply(1.0), 1.0, accuracy: 0.001)
    }

    func testQuadraticZeroInput() {
        let curve = ResponseCurve.quadratic

        XCTAssertEqual(curve.apply(0.0), 0.0, accuracy: 0.001)
    }

    // MARK: - Cubic

    func testCubicHalfInput() {
        let curve = ResponseCurve.cubic

        // 0.5^3 = 0.125
        XCTAssertEqual(curve.apply(0.5), 0.125, accuracy: 0.001)
    }

    func testCubicFullInput() {
        let curve = ResponseCurve.cubic

        XCTAssertEqual(curve.apply(1.0), 1.0, accuracy: 0.001)
    }

    func testCubicZeroInput() {
        let curve = ResponseCurve.cubic

        XCTAssertEqual(curve.apply(0.0), 0.0, accuracy: 0.001)
    }

    // MARK: - S-Curve

    func testSCurveMidpointIsHalf() {
        let curve = ResponseCurve.sCurve

        // 3*(0.5)^2 - 2*(0.5)^3 = 0.75 - 0.25 = 0.5
        XCTAssertEqual(curve.apply(0.5), 0.5, accuracy: 0.001)
    }

    func testSCurveZero() {
        let curve = ResponseCurve.sCurve

        XCTAssertEqual(curve.apply(0.0), 0.0, accuracy: 0.001)
    }

    func testSCurveOne() {
        let curve = ResponseCurve.sCurve

        // 3*(1)^2 - 2*(1)^3 = 3 - 2 = 1
        XCTAssertEqual(curve.apply(1.0), 1.0, accuracy: 0.001)
    }

    func testSCurveSmallInputBelowLinear() {
        let curve = ResponseCurve.sCurve

        // For x=0.2: 3*(0.04) - 2*(0.008) = 0.12 - 0.016 = 0.104
        // S-curve at small inputs is below linear (0.104 < 0.2)
        XCTAssertLessThan(curve.apply(0.2), 0.2)
    }

    func testSCurveLargeInputAboveLinear() {
        let curve = ResponseCurve.sCurve

        // For x=0.8: 3*(0.64) - 2*(0.512) = 1.92 - 1.024 = 0.896
        // S-curve at large inputs is above linear (0.896 > 0.8)
        XCTAssertGreaterThan(curve.apply(0.8), 0.8)
    }

    // MARK: - Custom curve

    func testCustomLinearPointsActLikeLinear() {
        let curve = ResponseCurve.custom(points: [(x: 0.0, y: 0.0), (x: 1.0, y: 1.0)])

        XCTAssertEqual(curve.apply(0.5), 0.5, accuracy: 0.001)
    }

    func testCustomCurveInterpolatesBetweenPoints() {
        let curve = ResponseCurve.custom(points: [
            (x: 0.0, y: 0.0),
            (x: 0.5, y: 0.8),
            (x: 1.0, y: 1.0),
        ])

        // Between (0, 0) and (0.5, 0.8): at x=0.25, t=0.5, y = 0 + 0.5*0.8 = 0.4
        XCTAssertEqual(curve.apply(0.25), 0.4, accuracy: 0.001)

        // Between (0.5, 0.8) and (1.0, 1.0): at x=0.75, t=0.5, y = 0.8 + 0.5*0.2 = 0.9
        XCTAssertEqual(curve.apply(0.75), 0.9, accuracy: 0.001)
    }

    func testCustomEmptyPointsFallsBackToLinear() {
        let curve = ResponseCurve.custom(points: [])

        XCTAssertEqual(curve.apply(0.5), 0.5, accuracy: 0.001)
    }

    // MARK: - Negative values

    func testNegativeValuePreservesSign() {
        let curve = ResponseCurve.quadratic

        // apply(-0.5) should be -(0.5^2) = -0.25
        XCTAssertEqual(curve.apply(-0.5), -0.25, accuracy: 0.001)
    }

    func testNegativeOneReturnsNegativeOne() {
        let curve = ResponseCurve.linear

        XCTAssertEqual(curve.apply(-1.0), -1.0, accuracy: 0.001)
    }

    // MARK: - Init from config

    func testInitFromLinearConfig() {
        let config = ResponseCurveConfig(type: .linear)
        let curve = ResponseCurve(from: config)

        XCTAssertEqual(curve.apply(0.7), 0.7, accuracy: 0.001)
    }

    func testInitFromQuadraticConfig() {
        let config = ResponseCurveConfig(type: .quadratic)
        let curve = ResponseCurve(from: config)

        XCTAssertEqual(curve.apply(0.5), 0.25, accuracy: 0.001)
    }

    func testInitFromCubicConfig() {
        let config = ResponseCurveConfig(type: .cubic)
        let curve = ResponseCurve(from: config)

        XCTAssertEqual(curve.apply(0.5), 0.125, accuracy: 0.001)
    }

    func testInitFromSCurveConfig() {
        let config = ResponseCurveConfig(type: .sCurve)
        let curve = ResponseCurve(from: config)

        XCTAssertEqual(curve.apply(0.5), 0.5, accuracy: 0.001)
    }

    func testInitFromCustomConfig() {
        let config = ResponseCurveConfig(
            type: .custom,
            customPoints: [[0.0, 0.0], [1.0, 1.0]]
        )
        let curve = ResponseCurve(from: config)

        XCTAssertEqual(curve.apply(0.5), 0.5, accuracy: 0.001)
    }
}
