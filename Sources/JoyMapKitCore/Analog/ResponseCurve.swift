import Foundation

/// Response curve implementations for analog input processing.
public enum ResponseCurve {
    case linear
    case quadratic
    case cubic
    case sCurve
    case custom(points: [(x: Double, y: Double)])

    public init(from config: ResponseCurveConfig) {
        switch config.type {
        case .linear:    self = .linear
        case .quadratic: self = .quadratic
        case .cubic:     self = .cubic
        case .sCurve:    self = .sCurve
        case .custom:
            let points = (config.customPoints ?? []).compactMap { arr -> (x: Double, y: Double)? in
                guard arr.count >= 2 else { return nil }
                return (x: arr[0], y: arr[1])
            }
            self = .custom(points: points)
        }
    }

    /// Apply the response curve to a normalized input value.
    /// - Parameter input: Value in range -1.0 to 1.0
    /// - Returns: Transformed value in range -1.0 to 1.0
    public func apply(_ input: Double) -> Double {
        let sign = input < 0 ? -1.0 : 1.0
        let magnitude = abs(input)

        let result: Double
        switch self {
        case .linear:
            result = magnitude
        case .quadratic:
            result = magnitude * magnitude
        case .cubic:
            result = magnitude * magnitude * magnitude
        case .sCurve:
            // Smooth S-curve: 3x^2 - 2x^3
            result = 3 * magnitude * magnitude - 2 * magnitude * magnitude * magnitude
        case .custom(let points):
            result = interpolate(magnitude, points: points)
        }

        return result * sign
    }

    private func interpolate(_ x: Double, points: [(x: Double, y: Double)]) -> Double {
        guard !points.isEmpty else { return x }

        // Find the two surrounding points and lerp
        for i in 0..<points.count - 1 {
            let p0 = points[i]
            let p1 = points[i + 1]
            if x >= p0.x && x <= p1.x {
                let t = (x - p0.x) / (p1.x - p0.x)
                return p0.y + t * (p1.y - p0.y)
            }
        }

        // Extrapolate from last point
        return points.last?.y ?? x
    }
}
