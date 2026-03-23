import SwiftUI
import JoyMapKitCore

struct ResponseCurveView: View {
    @Binding var curveConfig: ResponseCurveConfig

    private let canvasSize: CGFloat = 200
    private let controlPointRadius: CGFloat = 8

    var body: some View {
        VStack(spacing: 12) {
            canvas
            curvePicker
        }
    }

    // MARK: - Canvas

    private var canvas: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            drawGrid(context: context, size: size)
            drawReferenceLine(context: context, w: w, h: h)
            drawCurve(context: context, w: w, h: h)
        }
        .frame(width: canvasSize, height: canvasSize)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(controlPointOverlay)
    }

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        var gridPath = Path()
        for i in 1..<4 {
            let x = w * CGFloat(i) / 4
            gridPath.move(to: CGPoint(x: x, y: 0))
            gridPath.addLine(to: CGPoint(x: x, y: h))

            let y = h * CGFloat(i) / 4
            gridPath.move(to: CGPoint(x: 0, y: y))
            gridPath.addLine(to: CGPoint(x: w, y: y))
        }
        context.stroke(gridPath, with: .color(.gray.opacity(0.25)), lineWidth: 0.5)
    }

    private func drawReferenceLine(context: GraphicsContext, w: CGFloat, h: CGFloat) {
        var refPath = Path()
        refPath.move(to: CGPoint(x: 0, y: h))
        refPath.addLine(to: CGPoint(x: w, y: 0))
        context.stroke(
            refPath,
            with: .color(.gray.opacity(0.35)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )
    }

    private func drawCurve(context: GraphicsContext, w: CGFloat, h: CGFloat) {
        let curve = ResponseCurve(from: curveConfig)
        var curvePath = Path()
        let sampleCount = 100
        for i in 0...sampleCount {
            let t = Double(i) / Double(sampleCount)
            let output = curve.apply(t)
            let point = CGPoint(x: w * t, y: h * (1 - output))
            if i == 0 {
                curvePath.move(to: point)
            } else {
                curvePath.addLine(to: point)
            }
        }
        context.stroke(curvePath, with: .color(.blue), lineWidth: 2)
    }

    // MARK: - Control Points (custom mode)

    @ViewBuilder
    private var controlPointOverlay: some View {
        if curveConfig.type == .custom, let points = curveConfig.customPoints {
            GeometryReader { geo in
                ForEach(points.indices, id: \.self) { index in
                    let px = points[index][0]
                    let py = points[index][1]
                    Circle()
                        .fill(Color.blue)
                        .frame(width: controlPointRadius * 2, height: controlPointRadius * 2)
                        .position(
                            x: geo.size.width * px,
                            y: geo.size.height * (1 - py)
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let newX = clamp(value.location.x / geo.size.width)
                                    let newY = clamp(1.0 - Double(value.location.y / geo.size.height))
                                    curveConfig.customPoints?[index] = [newX, newY]
                                }
                        )
                }
            }
            .frame(width: canvasSize, height: canvasSize)
        }
    }

    // MARK: - Picker

    private var curvePicker: some View {
        Picker("Curve", selection: $curveConfig.type) {
            Text("Linear").tag(ResponseCurveConfig.ResponseCurveType.linear)
            Text("Quadratic").tag(ResponseCurveConfig.ResponseCurveType.quadratic)
            Text("Cubic").tag(ResponseCurveConfig.ResponseCurveType.cubic)
            Text("S-Curve").tag(ResponseCurveConfig.ResponseCurveType.sCurve)
            Text("Custom").tag(ResponseCurveConfig.ResponseCurveType.custom)
        }
        .pickerStyle(.segmented)
        .onChange(of: curveConfig.type) { newType in
            if newType == .custom && (curveConfig.customPoints ?? []).isEmpty {
                curveConfig.customPoints = [[0, 0], [0.5, 0.5], [1, 1]]
            }
        }
    }

    // MARK: - Helpers

    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
