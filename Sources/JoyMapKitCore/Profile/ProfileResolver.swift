import Foundation

/// Determines which profile should be active based on the focused app and connected controller.
public final class ProfileResolver {
    private var profiles: [Profile] = []

    public init() {}

    public func updateProfiles(_ profiles: [Profile]) {
        self.profiles = profiles
    }

    /// Resolution order:
    /// 1. Profile matching both app bundle ID AND controller type
    /// 2. Profile matching app bundle ID (any controller)
    /// 3. Profile with appBundleIDs = ["*"] (fallback/default)
    /// 4. nil (no mapping active)
    public func resolve(forApp app: AppIdentifier?, controller: ControllerHandle?) -> Profile? {
        guard let app else {
            return fallbackProfile()
        }

        // 1. Match app + controller type
        if let controllerType = controller?.controllerType {
            if let match = profiles.first(where: { profile in
                profile.appBundleIDs.contains(app.bundleID) &&
                profile.controllerTypes?.contains(controllerType) == true
            }) {
                return match
            }
        }

        // 2. Match app only (no controller type filter)
        if let match = profiles.first(where: { profile in
            profile.appBundleIDs.contains(app.bundleID) &&
            profile.controllerTypes == nil
        }) {
            return match
        }

        // 3. Fallback profile (wildcard)
        return fallbackProfile()
    }

    private func fallbackProfile() -> Profile? {
        profiles.first { $0.appBundleIDs.contains("*") }
    }
}
