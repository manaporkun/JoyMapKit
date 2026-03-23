import Foundation
import GameController
import Logging

/// Protocol for controller management, enabling testability.
public protocol ControllerManaging: AnyObject {
    var connectedControllers: [ControllerHandle] { get }
    var onControllerConnected: ((ControllerHandle) -> Void)? { get set }
    var onControllerDisconnected: ((ControllerHandle) -> Void)? { get set }
    var onInputChanged: ((ControllerHandle, String, Float) -> Void)? { get set }
    func startMonitoring()
    func stopMonitoring()
}

/// Manages game controller lifecycle and input events using Apple's GameController framework.
public final class ControllerManager: ControllerManaging {
    public private(set) var connectedControllers: [ControllerHandle] = []
    public var onControllerConnected: ((ControllerHandle) -> Void)?
    public var onControllerDisconnected: ((ControllerHandle) -> Void)?
    /// Called when any input changes. Parameters: controller handle, element name, value (0-1 for buttons/triggers, -1 to 1 for axes).
    public var onInputChanged: ((ControllerHandle, String, Float) -> Void)?

    private let logger = Logger(label: "com.joymapkit.controller")
    private var connectObserver: Any?
    private var disconnectObserver: Any?
    private let enableBackgroundMonitoring: Bool

    public init(enableBackgroundMonitoring: Bool = true) {
        self.enableBackgroundMonitoring = enableBackgroundMonitoring
    }

    public func startMonitoring() {
        connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            self?.controllerConnected(controller)
        }

        disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            self?.controllerDisconnected(controller)
        }

        // Handle controllers already connected at launch
        for controller in GCController.controllers() {
            controllerConnected(controller)
        }

        logger.info("Controller monitoring started (\(GCController.controllers().count) connected)")
    }

    public func stopMonitoring() {
        if let observer = connectObserver {
            NotificationCenter.default.removeObserver(observer)
            connectObserver = nil
        }
        if let observer = disconnectObserver {
            NotificationCenter.default.removeObserver(observer)
            disconnectObserver = nil
        }
        connectedControllers.removeAll()
        logger.info("Controller monitoring stopped")
    }

    // MARK: - Private

    private func controllerConnected(_ controller: GCController) {
        // Enable background event monitoring after first connection
        if enableBackgroundMonitoring {
            GCController.shouldMonitorBackgroundEvents = true
        }

        let handle = ControllerHandle(controller: controller)
        connectedControllers.append(handle)
        configureInputHandlers(for: handle)

        logger.info("Controller connected: \(handle.vendorName) (\(handle.controllerType.rawValue), \(handle.availableElements.count) elements)")
        onControllerConnected?(handle)
    }

    private func controllerDisconnected(_ controller: GCController) {
        guard let index = connectedControllers.firstIndex(where: { $0.controller === controller }) else {
            return
        }

        let handle = connectedControllers.remove(at: index)
        logger.info("Controller disconnected: \(handle.vendorName)")
        onControllerDisconnected?(handle)
    }

    private func configureInputHandlers(for handle: ControllerHandle) {
        guard let gamepad = handle.controller?.extendedGamepad else {
            logger.warning("Controller \(handle.vendorName) has no extended gamepad profile")
            return
        }

        // Master handler: fires on ANY input change
        gamepad.valueChangedHandler = { [weak self, weak handle] (gamepad, element) in
            guard let self, let handle else { return }

            // Find the element name by matching against the physical input profile
            if let profile = handle.controller?.physicalInputProfile {
                for (name, profileElement) in profile.elements {
                    if profileElement === element {
                        let value: Float
                        if let button = element as? GCControllerButtonInput {
                            value = button.value
                        } else if let axis = element as? GCControllerAxisInput {
                            value = axis.value
                        } else if let dpad = element as? GCDeviceDirectionPad {
                            // For dpads, report individual directions
                            self.reportDpadInput(handle: handle, name: name, dpad: dpad)
                            return
                        } else {
                            value = 0
                        }
                        self.onInputChanged?(handle, name, value)
                        return
                    }
                }
            }
        }
    }

    private func reportDpadInput(handle: ControllerHandle, name: String, dpad: GCDeviceDirectionPad) {
        onInputChanged?(handle, "\(name) Up", dpad.up.value)
        onInputChanged?(handle, "\(name) Down", dpad.down.value)
        onInputChanged?(handle, "\(name) Left", dpad.left.value)
        onInputChanged?(handle, "\(name) Right", dpad.right.value)
    }
}
