import Foundation
import ApplicationServices

/// Checks and requests macOS Accessibility permissions required for CGEvent posting.
public struct PermissionChecker {
    /// Returns true if accessibility access is granted.
    public static func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    /// Checks accessibility access, optionally showing the system permission dialog.
    /// - Parameter prompt: If true, macOS will show the dialog directing the user to
    ///   System Settings > Privacy & Security > Accessibility.
    /// - Returns: Whether access is currently granted (the dialog is non-blocking).
    public static func checkAccessibility(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Polls for accessibility permission grant, calling the handler when granted.
    /// - Parameters:
    ///   - interval: Polling interval in seconds (default: 1.0).
    ///   - onGranted: Called on the main queue when permission is granted.
    /// - Returns: A timer that can be invalidated to stop polling.
    @discardableResult
    public static func pollForPermission(
        interval: TimeInterval = 1.0,
        onGranted: @escaping () -> Void
    ) -> Timer {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                DispatchQueue.main.async { onGranted() }
            }
        }
    }
}
