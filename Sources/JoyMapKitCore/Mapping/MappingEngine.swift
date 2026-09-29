import Foundation
import Logging

/// The heart of the system. Receives raw input events, resolves bindings, dispatches actions.
/// Supports single bindings, chords, layers, macros, and whileHeld auto-repeat.
/// - Important: All methods must be called from the main thread (GameController delivers on `.main` queue).
public final class MappingEngine {
    private var actionDispatcher: ActionDispatching
    private let chordDetector: ChordDetector
    private let layerManager: LayerManager
    private let macroRunner: MacroRunner
    private let logger = Logger(label: "com.joymapkit.engine")

    private struct HeldBinding {
        let action: ActionConfig
        let holdBehavior: HoldBehavior

        var hasPressedAction: Bool { holdBehavior != .onRelease }
    }

    private struct ActiveChord {
        let id = UUID()
        let action: ActionConfig
    }

    private var activeProfile: Profile?
    private var heldBindings: [String: HeldBinding] = [:]
    /// Each member references the same activation, which is released exactly once.
    private var activeChordActions: [String: ActiveChord] = [:]
    /// Timers for whileHeld auto-repeat, keyed by element name.
    private var whileHeldTimers: [String: Timer] = [:]
    /// Pre-indexed base bindings for O(1) lookup by element name.
    private var bindingIndex: [String: BindingConfig] = [:]
    /// Pre-indexed per-layer bindings for O(1) lookup.
    private var layerBindingIndices: [String: [String: BindingConfig]] = [:]

    // MARK: - Turbo State

    /// Elements with turbo toggled on (rapid-fire when held).
    private var turboElements: Set<String> = []
    /// Whether the turbo modifier button is currently held.
    private var turboButtonHeld: Bool = false
    /// Timers for turbo rapid-fire, keyed by element name.
    private var turboTimers: [String: Timer] = [:]
    /// The turbo rate for the active profile (milliseconds between fires).
    private var turboRateMs: Int = 80

    /// Called when turbo state changes (for UI feedback).
    public var onTurboChanged: ((_ turboElements: Set<String>) -> Void)?

    /// Handles analog stick and trigger inputs. Set by JoyMapService.
    public var analogHandler: AnalogHandler?

    /// Called when a profile switch is requested via a binding action.
    public var onProfileSwitchRequested: ((String) -> Void)?

    public init(actionDispatcher: ActionDispatching) {
        self.actionDispatcher = actionDispatcher
        self.chordDetector = ChordDetector()
        self.layerManager = LayerManager()
        self.macroRunner = MacroRunner(actionDispatcher: actionDispatcher)

        // Wire chord detector's deferred press callback
        chordDetector.onDeferredPress = { [weak self] elementName in
            self?.handleDeferredPress(elementName)
        }

        // Wire action dispatcher callbacks
        self.actionDispatcher.onMacro = { [weak self] macro, key, pressed in
            guard let self else { return }
            if pressed {
                self.macroRunner.start(macro, key: key)
            } else {
                self.macroRunner.cancel(key: key)
            }
        }

        self.actionDispatcher.onProfileSwitch = { [weak self] name in
            self?.onProfileSwitchRequested?(name)
        }

        self.actionDispatcher.onLayerToggle = { [weak self] name in
            self?.layerManager.toggle(name)
        }
    }

    /// Set the active mapping profile. Releases all held keys before switching.
    public func setProfile(_ profile: Profile?) {
        releaseAllHeldKeys()
        layerManager.deactivateAll()
        invalidateAllWhileHeldTimers()
        clearTurboState()

        activeProfile = profile

        if let profile {
            // Build pre-indexed binding lookups for O(1) resolution
            bindingIndex = [:]
            for binding in profile.bindings {
                if case .single(let name) = binding.input {
                    bindingIndex[name] = binding
                }
            }
            layerBindingIndices = [:]
            for layer in profile.layers {
                var index: [String: BindingConfig] = [:]
                for binding in layer.bindings {
                    if case .single(let name) = binding.input {
                        index[name] = binding
                    }
                }
                layerBindingIndices[layer.name] = index
            }

            // Configure chord detector with all chord bindings (base + layers)
            var allBindings = profile.bindings
            for layer in profile.layers {
                allBindings.append(contentsOf: layer.bindings)
            }
            chordDetector.configure(bindings: allBindings)
            turboRateMs = profile.turboRateMs ?? 80
            logger.info("Profile activated: \(profile.name)")
        } else {
            bindingIndex = [:]
            layerBindingIndices = [:]
        }
    }

    /// Handle an input event from a controller.
    public func handleInput(elementName: String, value: Float, from controller: ControllerHandle) {
        guard let profile = activeProfile else { return }

        // 1. Route analog inputs (sticks, triggers) to the analog pipeline first
        if let analogHandler, analogHandler.handleInput(elementName: elementName, value: value) {
            return
        }

        let pressed = value > 0.1

        // 2. Handle turbo modifier button
        if let turboButton = profile.turboButton, elementName == turboButton {
            turboButtonHeld = pressed
            return
        }

        // 3. If turbo modifier is held, toggle turbo on this element instead of dispatching
        if turboButtonHeld && pressed {
            toggleTurbo(for: elementName)
            return
        }

        // 4. Handle layer activators
        if handleLayerActivator(elementName: elementName, pressed: pressed, in: profile) {
            return
        }

        // 5. Handle turbo-active elements (rapid-fire on hold)
        if turboElements.contains(elementName) {
            handleTurboInput(elementName: elementName, pressed: pressed, in: profile)
            return
        }

        if pressed {
            handlePress(elementName: elementName, in: profile)
        } else {
            handleRelease(elementName: elementName)
        }
    }

    /// Cancel pending input and release held outputs on profile changes, stop, or disconnect.
    public func releaseAllHeldKeys() {
        chordDetector.reset()
        let held = Array(heldBindings.values)
        let chords = Array(activeChordActions.values)
        heldBindings.removeAll()
        activeChordActions.removeAll()

        invalidateAllWhileHeldTimers()
        for (_, timer) in turboTimers { timer.invalidate() }
        turboTimers.removeAll()
        macroRunner.cancelAll()

        for binding in held where binding.hasPressedAction {
            dispatch(binding.action, pressed: false)
        }
        var releasedChords = Set<UUID>()
        for chord in chords where releasedChords.insert(chord.id).inserted {
            dispatch(chord.action, pressed: false)
        }
    }

    // MARK: - Private — Press/Release Flow

    private func handlePress(elementName: String, in profile: Profile) {
        guard activeChordActions[elementName] == nil else { return }
        let wasHeld = heldBindings[elementName] != nil

        // Check chord detector first
        let chordResult = chordDetector.handlePress(elementName)

        switch chordResult {
        case .immediate:
            // Not a chord participant — resolve binding normally
            guard let binding = resolveBinding(for: elementName, in: profile) else { return }
            applyHoldBehavior(binding: binding, elementName: elementName, pressed: true, wasHeld: wasHeld)

        case .deferred:
            // Waiting for chord window — do nothing yet
            break

        case .chordMatched(let binding, let elements):
            // Chord matched — dispatch chord action, suppress individual actions
            let replacedChordIDs = Set(elements.compactMap { activeChordActions[$0]?.id })
            dispatch(binding.action, pressed: true)
            for id in replacedChordIDs {
                releaseChord(id: id)
            }
            let chord = ActiveChord(action: binding.action)
            for element in elements {
                activeChordActions[element] = chord
                // Remove any pending single presses from held state
                if let held = heldBindings.removeValue(forKey: element), held.hasPressedAction {
                    dispatch(held.action, pressed: false)
                }
                invalidateWhileHeldTimer(for: element)
            }
        }
    }

    private func handleRelease(elementName: String) {
        chordDetector.handleRelease(elementName)

        // Check if this element was part of an active chord
        if let chord = activeChordActions[elementName] {
            // Release the chord action when the first chord member is released
            releaseChord(id: chord.id)
            return
        }

        // Normal release for single bindings
        if let held = heldBindings[elementName] {
            switch held.holdBehavior {
            case .onPress, .whileHeld:
                dispatch(held.action, pressed: false)
                heldBindings.removeValue(forKey: elementName)
                invalidateWhileHeldTimer(for: elementName)

            case .onRelease:
                // Tap on release
                dispatch(held.action, pressed: true)
                dispatch(held.action, pressed: false)
                heldBindings.removeValue(forKey: elementName)

            case .toggle:
                // Toggle doesn't release on button release — it toggles on next press
                break
            }
        }
    }

    private func releaseChord(id: UUID) {
        guard let chord = activeChordActions.values.first(where: { $0.id == id }) else { return }
        activeChordActions = activeChordActions.filter { $0.value.id != id }
        dispatch(chord.action, pressed: false)
    }

    /// Called by ChordDetector when the chord window expires for a deferred press.
    private func handleDeferredPress(_ elementName: String) {
        guard let profile = activeProfile else { return }
        let wasHeld = heldBindings[elementName] != nil
        guard let binding = resolveBinding(for: elementName, in: profile) else { return }
        applyHoldBehavior(binding: binding, elementName: elementName, pressed: true, wasHeld: wasHeld)
    }

    // MARK: - Private — Hold Behavior

    private func applyHoldBehavior(binding: BindingConfig, elementName: String, pressed: Bool, wasHeld: Bool) {
        let holdBehavior = binding.holdBehavior ?? .onPress

        // Toggle must be handled before the general guard since it needs to fire on re-press
        if case .toggle = holdBehavior, pressed {
            if let held = heldBindings[elementName] {
                dispatch(held.action, pressed: false)
                heldBindings.removeValue(forKey: elementName)
            } else {
                dispatch(binding.action, pressed: true)
                heldBindings[elementName] = HeldBinding(action: binding.action, holdBehavior: holdBehavior)
            }
            return
        }

        guard pressed && !wasHeld else { return }

        switch holdBehavior {
        case .onPress:
            dispatch(binding.action, pressed: true)
            heldBindings[elementName] = HeldBinding(action: binding.action, holdBehavior: holdBehavior)

        case .onRelease:
            // Just track that it's held — action fires on release
            heldBindings[elementName] = HeldBinding(action: binding.action, holdBehavior: holdBehavior)

        case .toggle:
            break // Already handled above

        case .whileHeld(let repeatIntervalMs):
            dispatch(binding.action, pressed: true)
            heldBindings[elementName] = HeldBinding(action: binding.action, holdBehavior: holdBehavior)
            startWhileHeldTimer(for: elementName, action: binding.action, intervalMs: repeatIntervalMs)
        }
    }

    // MARK: - Private — whileHeld Auto-Repeat

    private func startWhileHeldTimer(for elementName: String, action: ActionConfig, intervalMs: Int) {
        invalidateWhileHeldTimer(for: elementName)
        let interval = Double(max(intervalMs, 10)) / 1000.0
        whileHeldTimers[elementName] = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            // Tap: release then press to simulate repeated key taps
            self?.dispatch(action, pressed: false)
            self?.dispatch(action, pressed: true)
        }
    }

    private func invalidateWhileHeldTimer(for elementName: String) {
        whileHeldTimers[elementName]?.invalidate()
        whileHeldTimers.removeValue(forKey: elementName)
    }

    private func invalidateAllWhileHeldTimers() {
        for (_, timer) in whileHeldTimers {
            timer.invalidate()
        }
        whileHeldTimers.removeAll()
    }

    // MARK: - Private — Layer Activators

    /// Check if this element is a layer activator. Returns true if consumed.
    private func handleLayerActivator(elementName: String, pressed: Bool, in profile: Profile) -> Bool {
        for layer in profile.layers {
            if case .single(let activatorElement) = layer.activator, activatorElement == elementName {
                if pressed {
                    layerManager.activate(layer.name)
                } else {
                    layerManager.deactivate(layer.name)
                }
                return true
            }
        }
        return false
    }

    // MARK: - Private — Binding Resolution

    /// Resolve a binding for a single element, checking active layers first (most recently activated wins),
    /// then falling back to base profile bindings. Uses pre-indexed dictionaries for O(1) lookup.
    private func resolveBinding(for elementName: String, in profile: Profile) -> BindingConfig? {
        // Check active layers in activation order so the last-activated layer wins.
        for layerName in layerManager.activeLayersInPriorityOrder {
            if let binding = layerBindingIndices[layerName]?[elementName] {
                return binding
            }
        }

        // Fall back to base bindings
        return bindingIndex[elementName]
    }

    // MARK: - Private — Turbo

    private func toggleTurbo(for elementName: String) {
        if turboElements.contains(elementName) {
            turboElements.remove(elementName)
            invalidateTurboTimer(for: elementName)
            logger.info("Turbo OFF: \(elementName)")
        } else {
            turboElements.insert(elementName)
            logger.info("Turbo ON: \(elementName)")
        }
        onTurboChanged?(turboElements)
    }

    private func handleTurboInput(elementName: String, pressed: Bool, in profile: Profile) {
        if pressed {
            guard heldBindings[elementName] == nil else { return }
            guard let binding = resolveBinding(for: elementName, in: profile) else { return }
            // Start rapid-fire: immediate first press, then repeat at turbo rate
            dispatch(binding.action, pressed: true)
            heldBindings[elementName] = HeldBinding(action: binding.action, holdBehavior: .onPress)

            let interval = Double(max(turboRateMs, 10)) / 1000.0
            turboTimers[elementName]?.invalidate()
            turboTimers[elementName] = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.dispatch(binding.action, pressed: false)
                self?.dispatch(binding.action, pressed: true)
            }
        } else {
            // Release
            if let held = heldBindings.removeValue(forKey: elementName) {
                dispatch(held.action, pressed: false)
            }
            invalidateTurboTimer(for: elementName)
        }
    }

    private func invalidateTurboTimer(for elementName: String) {
        turboTimers[elementName]?.invalidate()
        turboTimers.removeValue(forKey: elementName)
    }

    private func clearTurboState() {
        turboElements.removeAll()
        turboButtonHeld = false
        for (_, timer) in turboTimers { timer.invalidate() }
        turboTimers.removeAll()
        onTurboChanged?(turboElements)
    }

    private func dispatch(_ action: ActionConfig, pressed: Bool) {
        do {
            try actionDispatcher.dispatch(action, pressed: pressed)
        } catch {
            logger.error("Failed to dispatch action: \(error)")
        }
    }
}
