import Foundation
import Logging

/// Top-level orchestrator that wires all components together and manages lifecycle.
public final class JoyMapService {
    public private(set) var status: ServiceStatus

    private let configManager: ConfigManager
    private let profileStore: ProfileStore
    private let controllerManager: ControllerManager
    private let focusedAppMonitor: FocusedAppMonitor
    private let profileResolver: ProfileResolver
    private let mappingEngine: MappingEngine
    private let logger = Logger(label: "com.joymapkit.service")

    private var config: GlobalConfig

    public init(configDirectory: URL? = nil) throws {
        let configDir = configDirectory ?? ConfigManager.defaultConfigDirectory
        self.configManager = ConfigManager(configDirectory: configDir)
        self.profileStore = ProfileStore(configDirectory: configDir)
        self.controllerManager = ControllerManager()
        self.focusedAppMonitor = FocusedAppMonitor()
        self.profileResolver = ProfileResolver()

        let keySimulator = KeySimulator()
        let mouseSimulator = MouseSimulator()
        let actionDispatcher = ActionDispatcher(
            keySimulator: keySimulator,
            mouseSimulator: mouseSimulator
        )
        self.mappingEngine = MappingEngine(actionDispatcher: actionDispatcher)

        self.config = try configManager.load()
        self.status = ServiceStatus()
    }

    public func start(profileOverride: String? = nil, autoSwitch: Bool = true) throws {
        // Check accessibility
        let hasAccess = PermissionChecker.checkAccessibility(prompt: true)
        status.accessibilityGranted = hasAccess
        if !hasAccess {
            logger.warning("Accessibility permission not granted. Key simulation will not work until granted.")
            logger.info("Go to System Settings > Privacy & Security > Accessibility")
        }

        // Load profiles
        let profiles = (try? profileStore.loadAll()) ?? []
        profileResolver.updateProfiles(profiles)
        logger.info("Loaded \(profiles.count) profile(s)")

        // Activate initial profile
        let initialProfileName = profileOverride ?? config.profiles.defaultProfile
        if let profile = profiles.first(where: { $0.name == initialProfileName }) {
            mappingEngine.setProfile(profile)
            status.activeProfileName = profile.name
        } else if let fallback = profiles.first(where: { $0.appBundleIDs.contains("*") }) {
            mappingEngine.setProfile(fallback)
            status.activeProfileName = fallback.name
        } else {
            logger.warning("No profile found matching '\(initialProfileName)' and no fallback profile")
        }

        // Wire controller events to mapping engine
        controllerManager.onControllerConnected = { [weak self] handle in
            self?.onControllerConnected(handle)
        }
        controllerManager.onControllerDisconnected = { [weak self] handle in
            self?.onControllerDisconnected(handle)
        }
        controllerManager.onInputChanged = { [weak self] handle, elementName, value in
            self?.mappingEngine.handleInput(elementName: elementName, value: value, from: handle)
        }

        // Wire app focus changes for auto-switching
        if autoSwitch {
            focusedAppMonitor.onAppChanged = { [weak self] app in
                self?.onAppChanged(app)
            }
            focusedAppMonitor.startMonitoring()
        }

        // Start controller monitoring
        controllerManager.startMonitoring()

        status.isRunning = true
        status.focusedApp = focusedAppMonitor.currentApp
        logger.info("JoyMapKit service started")
    }

    public func stop() {
        mappingEngine.releaseAllHeldKeys()
        controllerManager.stopMonitoring()
        focusedAppMonitor.stopMonitoring()
        status.isRunning = false
        logger.info("JoyMapKit service stopped")
    }

    // MARK: - Callbacks

    private func onControllerConnected(_ handle: ControllerHandle) {
        status.connectedControllers.append(
            ServiceStatus.ControllerSummary(
                name: handle.vendorName,
                type: handle.controllerType,
                elementCount: handle.availableElements.count
            )
        )
        logger.info("Controller connected: \(handle.vendorName)")

        // Re-resolve profile with new controller
        if let app = focusedAppMonitor.currentApp,
           let profile = profileResolver.resolve(forApp: app, controller: handle) {
            mappingEngine.setProfile(profile)
            status.activeProfileName = profile.name
        }
    }

    private func onControllerDisconnected(_ handle: ControllerHandle) {
        status.connectedControllers.removeAll { $0.name == handle.vendorName }
        mappingEngine.releaseAllHeldKeys()
        logger.info("Controller disconnected: \(handle.vendorName)")
    }

    private func onAppChanged(_ app: AppIdentifier) {
        status.focusedApp = app

        guard let controller = controllerManager.connectedControllers.first else { return }

        if let profile = profileResolver.resolve(forApp: app, controller: controller) {
            if profile.name != status.activeProfileName {
                mappingEngine.setProfile(profile)
                status.activeProfileName = profile.name
                logger.info("Auto-switched to profile: \(profile.name) for \(app)")
            }
        }
    }
}
