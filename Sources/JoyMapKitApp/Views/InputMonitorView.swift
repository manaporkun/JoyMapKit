import SwiftUI

struct InputMonitorView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(.blue)
                Text("Input Monitor")
                    .font(.headline)
                Spacer()

                if !viewModel.controllers.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text(viewModel.controllers.first?.name ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Clear") {
                    viewModel.inputEvents.removeAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()

            Divider()

            if viewModel.controllers.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Connect a controller to see input events")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else if viewModel.inputEvents.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Press buttons or move sticks")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                // Event table
                List {
                    ForEach(viewModel.inputEvents.reversed()) { event in
                        InputEventRow(event: event)
                    }
                }
                .listStyle(.inset)
            }
        }
        .onAppear {
            viewModel.showInputMonitor = true
        }
        .onDisappear {
            viewModel.showInputMonitor = false
        }
    }
}

struct InputEventRow: View {
    let event: AppViewModel.InputEvent

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private var timeString: String {
        Self.timeFormatter.string(from: event.timestamp)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(timeString)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Text(event.elementName)
                .font(.system(.body, design: .monospaced))
                .frame(width: 200, alignment: .leading)

            // Value bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: max(0, geometry.size.width * CGFloat(abs(event.value))))
                }
            }
            .frame(height: 16)

            Text(String(format: "%+.2f", event.value))
                .font(.system(.caption, design: .monospaced))
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    private var barColor: Color {
        let v = abs(event.value)
        if v > 0.9 { return .red }
        if v > 0.5 { return .orange }
        return .blue
    }
}
