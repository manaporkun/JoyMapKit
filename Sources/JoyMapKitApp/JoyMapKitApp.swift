import SwiftUI
import JoyMapKitCore

@main
struct JoyMapKitApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
                .frame(width: 320)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.isEnabled
                    ? (viewModel.controllers.isEmpty ? "gamecontroller" : "gamecontroller.fill")
                    : "gamecontroller")
                if !viewModel.controllers.isEmpty {
                    Text("\(viewModel.controllers.count)")
                        .font(.caption2)
                }
            }
        }
        .menuBarExtraStyle(.window)

        Window("Input Monitor", id: "input-monitor") {
            InputMonitorView(viewModel: viewModel)
                .frame(minWidth: 500, minHeight: 400)
        }

        Window("Controller Test", id: "controller-test") {
            ControllerTestView(viewModel: viewModel)
                .frame(minWidth: 500, minHeight: 400)
        }

        Window("Profile Editor", id: "profile-editor") {
            ProfileEditorView(viewModel: viewModel)
                .frame(minWidth: 700, minHeight: 500)
        }

        Window("Rhythm Game", id: "rhythm-game") {
            RhythmGameView()
                .frame(minWidth: 500, minHeight: 450)
        }

        Window("About JoyMapKit", id: "about") {
            AboutView()
                .frame(width: 340, height: 260)
        }
    }
}
