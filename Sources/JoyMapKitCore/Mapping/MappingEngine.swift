import Foundation
import Logging

/// The heart of the system. Receives raw input events, resolves bindings, dispatches actions.
public final class MappingEngine {
    private let actionDispatcher: ActionDispatching
    private let logger = Logger(label: "com.joymapkit.engine")

    private var activeProfile: Profile?
    private var heldBindings: [String: ActionConfig] = [:]

    public init(actionDispatcher: ActionDispatching) {
        self.actionDispatcher = actionDispatcher
    }

    /// Set the active mapping profile. Releases all held keys before switching.
    public func setProfile(_ profile: Profile?) {
        releaseAllHeldKeys()
        activeProfile = profile
        if let profile {
            logger.info("Profile activated: \(profile.name)")
        }
    }

    /// Handle an input event from a controller.
    /// - Parameters:
    ///   - elementName: The canonical name of the input element (from GCPhysicalInputProfile).
    ///   - value: The input value (0.0 = released, >0 = pressed/active for buttons; -1 to 1 for axes).
    ///   - controller: The controller handle that generated the event.
    public func handleInput(elementName: String, value: Float, from controller: ControllerHandle) {
        guard let profile = activeProfile else { return }

        let pressed = value > 0.1
        let wasHeld = heldBindings[elementName] != nil

        // Find matching binding for this input
        guard let binding = findBinding(for: elementName, in: profile) else { return }

        let holdBehavior = binding.holdBehavior ?? .onPress

        switch holdBehavior {
        case .onPress:
            if pressed && !wasHeld {
                dispatch(binding.action, pressed: true)
                heldBindings[elementName] = binding.action
            } else if !pressed && wasHeld {
                dispatch(binding.action, pressed: false)
                heldBindings.removeValue(forKey: elementName)
            }

        case .onRelease:
            if pressed && !wasHeld {
                heldBindings[elementName] = binding.action
            } else if !pressed && wasHeld {
                // Tap on release
                dispatch(binding.action, pressed: true)
                dispatch(binding.action, pressed: false)
                heldBindings.removeValue(forKey: elementName)
            }

        case .toggle:
            if pressed && !wasHeld {
                if heldBindings[elementName] != nil {
                    dispatch(binding.action, pressed: false)
                    heldBindings.removeValue(forKey: elementName)
                } else {
                    dispatch(binding.action, pressed: true)
                    heldBindings[elementName] = binding.action
                }
            }

        case .whileHeld:
            // Basic implementation: same as onPress for now
            // Phase 4 will add auto-repeat timer
            if pressed && !wasHeld {
                dispatch(binding.action, pressed: true)
                heldBindings[elementName] = binding.action
            } else if !pressed && wasHeld {
                dispatch(binding.action, pressed: false)
                heldBindings.removeValue(forKey: elementName)
            }
        }
    }

    /// Release all currently held keys. Called during profile switches.
    public func releaseAllHeldKeys() {
        for (_, action) in heldBindings {
            dispatch(action, pressed: false)
        }
        heldBindings.removeAll()
    }

    // MARK: - Private

    private func findBinding(for elementName: String, in profile: Profile) -> BindingConfig? {
        // Check base-level bindings (no layer filtering in Phase 1)
        profile.bindings.first { binding in
            switch binding.input {
            case .single(let name):
                return name == elementName
            case .chord, .sequence:
                // Phase 4: chord/sequence matching
                return false
            }
        }
    }

    private func dispatch(_ action: ActionConfig, pressed: Bool) {
        do {
            try actionDispatcher.dispatch(action, pressed: pressed)
        } catch {
            logger.error("Failed to dispatch action: \(error)")
        }
    }
}
