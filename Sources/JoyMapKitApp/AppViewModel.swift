import Foundation
import SwiftUI
import GameController
import JoyMapKitCore
import Combine
import os.log

private let logger = Logger(subsystem: "com.joymapkit.app", category: "AppViewModel")

/// Main view model that drives the entire app state.
@MainActor
final class AppViewModel: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var controllers: [ControllerInfo] = []
    @Published var activeProfileName: String? = nil
    @Published var profiles: [ProfileInfo] = []
    @Published var focusedApp: String = "None"
    @Published var accessibilityGranted: Bool = false
    @Published var inputEvents: [InputEvent] = []
    @Published var showInputMonitor: Bool = false
    @Published var liveInputStates: [String: Float] = [:]
    @Published var loadError: String?

    private var service: JoyMapService?
    private var controllerManager: ControllerManager?
    private var permissionTimer: Timer?
    private var displayTimer: Timer?
    private var inputBuffer: [String: Float] = [:]

    struct ControllerInfo: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let elementCount: Int
    }

    struct ProfileInfo: Identifiable {
        let id: UUID
        let name: String
        let appBundleIDs: [String]
        let bindingCount: Int
    }

    struct InputEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let elementName: String
        let value: Float
    }

    init() {
        accessibilityGranted = PermissionChecker.isAccessibilityGranted()
        loadProfiles()
        startControllerMonitoring()
        startAccessibilityPolling()
    }

    func toggle() {
        isEnabled.toggle()
        if isEnabled {
            startService()
        } else {
            stopService()
        }
    }

    func startService() {
        do {
            let svc = try JoyMapService()
            try svc.start()
            service = svc
            activeProfileName = svc.status.activeProfileName
        } catch {
            logger.error("Failed to start service: \(error.localizedDescription)")
        }
    }

    func stopService() {
        service?.stop()
        service = nil
        activeProfileName = nil
    }

    func requestAccessibility() {
        _ = PermissionChecker.checkAccessibility(prompt: true)
        // Immediately recheck in case it was already granted
        recheckAccessibility()
    }

    func recheckAccessibility() {
        accessibilityGranted = PermissionChecker.isAccessibilityGranted()
    }

    private func startAccessibilityPolling() {
        // Always poll — each rebuild can change the codesign identity
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { timer.invalidate(); return }
                let granted = PermissionChecker.isAccessibilityGranted()
                if granted != self.accessibilityGranted {
                    self.accessibilityGranted = granted
                }
            }
        }
    }

    func selectProfile(_ name: String) {
        let oldProfileName = activeProfileName
        // Restart service with the new profile
        stopService()
        do {
            let svc = try JoyMapService()
            try svc.start(profileOverride: name)
            service = svc
            activeProfileName = name
        } catch {
            logger.error("Failed to switch profile: \(error.localizedDescription)")
            activeProfileName = oldProfileName
        }
    }

    func reloadProfiles() {
        loadProfiles()
    }

    // MARK: - Private

    private func loadProfiles() {
        let store = ProfileStore(configDirectory: ConfigManager.defaultConfigDirectory)
        let loaded: [Profile]
        do {
            loaded = try store.loadAll()
        } catch {
            logger.error("Failed to load profiles: \(error)")
            self.loadError = error.localizedDescription
            loaded = []
        }
        profiles = loaded.map { profile in
            ProfileInfo(
                id: profile.id,
                name: profile.name,
                appBundleIDs: profile.appBundleIDs,
                bindingCount: profile.bindings.count
            )
        }
    }

    private func startControllerMonitoring() {
        let manager = ControllerManager(enableBackgroundMonitoring: false)
        self.controllerManager = manager

        manager.onControllerConnected = { [weak self] handle in
            Task { @MainActor in
                self?.controllers.append(ControllerInfo(
                    name: handle.vendorName,
                    type: handle.controllerType.rawValue,
                    elementCount: handle.availableElements.count
                ))
            }
        }

        manager.onControllerDisconnected = { [weak self] handle in
            Task { @MainActor in
                self?.controllers.removeAll { $0.name == handle.vendorName }
            }
        }

        manager.onInputChanged = { [weak self] _, elementName, value in
            MainActor.assumeIsolated {
                guard let self else { return }
                // Buffer input for 60Hz flush
                self.inputBuffer[elementName] = value

                // Feed input monitor
                guard abs(value) > 0.01, self.showInputMonitor else { return }
                let event = InputEvent(timestamp: Date(), elementName: elementName, value: value)
                self.inputEvents.append(event)
                if self.inputEvents.count > 50 {
                    self.inputEvents.removeFirst(self.inputEvents.count - 50)
                }
            }
        }

        // 60Hz timer to flush buffered input to @Published property
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                guard !self.inputBuffer.isEmpty else { return }
                self.liveInputStates = self.inputBuffer
            }
        }

        manager.startMonitoring()
    }

    deinit {
        displayTimer?.invalidate()
        permissionTimer?.invalidate()
    }
}
