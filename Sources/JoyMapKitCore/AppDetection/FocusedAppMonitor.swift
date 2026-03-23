import Foundation
import AppKit
import Logging

/// Protocol for monitoring the frontmost application.
public protocol FocusedAppMonitoring: AnyObject {
    var currentApp: AppIdentifier? { get }
    var onAppChanged: ((AppIdentifier) -> Void)? { get set }
    func startMonitoring()
    func stopMonitoring()
}

/// Monitors which application is currently focused using NSWorkspace notifications.
public final class FocusedAppMonitor: FocusedAppMonitoring {
    public private(set) var currentApp: AppIdentifier?
    public var onAppChanged: ((AppIdentifier) -> Void)?

    private let logger = Logger(label: "com.joymapkit.appdetection")
    private var observer: Any?

    public init() {}

    public func startMonitoring() {
        // Set initial state
        if let frontmost = NSWorkspace.shared.frontmostApplication {
            currentApp = AppIdentifier(
                bundleID: frontmost.bundleIdentifier ?? "unknown",
                displayName: frontmost.localizedName ?? "Unknown"
            )
        }

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            let identifier = AppIdentifier(
                bundleID: app.bundleIdentifier ?? "unknown",
                displayName: app.localizedName ?? "Unknown"
            )
            self?.currentApp = identifier
            self?.logger.debug("App switched to: \(identifier)")
            self?.onAppChanged?(identifier)
        }

        logger.info("App focus monitoring started (current: \(currentApp?.description ?? "none"))")
    }

    public func stopMonitoring() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
        logger.info("App focus monitoring stopped")
    }
}
