import Foundation
import Logging

/// Result of pressing a button through the chord detection system.
public enum ChordResult {
    /// Element is not a chord participant — handle immediately as a single binding.
    case immediate
    /// Element is a chord participant but the chord hasn't completed — wait.
    case deferred
    /// A chord binding has been matched. The associated elements are consumed.
    case chordMatched(binding: BindingConfig, elements: Set<String>)
}

/// Detects simultaneous button presses within a configurable time window.
///
/// **Deferred-release strategy**: Buttons that participate in any chord binding use deferred dispatch.
/// On press, a chord window timer starts. If the chord completes within the window, the chord action
/// fires and individual actions are suppressed. If the window expires, deferred single-button actions fire.
/// Buttons NOT involved in any chord fire immediately with zero added latency.
public final class ChordDetector {
    public var chordWindowMs: Int

    /// Called when the chord window expires and deferred single presses should fire.
    public var onDeferredPress: ((String) -> Void)?

    /// Elements that appear in at least one chord binding.
    private var chordElements: Set<String> = []

    /// Lookup table: sorted chord element names → binding config.
    private var chordBindings: [[String]: BindingConfig] = [:]

    /// Currently-pressed elements that are chord participants.
    private var pressedChordElements: Set<String> = []

    /// Pending deferred single presses.
    private var pendingPresses = Set<String>()

    private var windowTimer: Timer?
    private let logger = Logger(label: "com.joymapkit.chord")

    public init(chordWindowMs: Int = 50) {
        self.chordWindowMs = chordWindowMs
    }

    /// Rebuild chord lookup tables from the profile's bindings.
    public func configure(bindings: [BindingConfig]) {
        reset()
        chordElements.removeAll()
        chordBindings.removeAll()

        for binding in bindings {
            if case .chord(let elements) = binding.input {
                let sorted = elements.sorted()
                chordBindings[sorted] = binding
                for element in elements {
                    chordElements.insert(element)
                }
            }
        }
    }

    /// Process a button press. Returns how the MappingEngine should handle it.
    public func handlePress(_ elementName: String) -> ChordResult {
        guard chordElements.contains(elementName) else {
            return .immediate
        }

        pressedChordElements.insert(elementName)
        pendingPresses.insert(elementName)

        // Check if current pressed set exactly matches any chord
        let pressedSorted = pressedChordElements.sorted()
        if let binding = chordBindings[pressedSorted] {
            let matchedElements = pressedChordElements
            windowTimer?.invalidate()
            windowTimer = nil
            pendingPresses.removeAll()
            // Don't clear pressedChordElements — we still track them for release
            logger.debug("Chord matched: \(pressedSorted)")
            return .chordMatched(binding: binding, elements: matchedElements)
        }

        // Start or restart chord window timer
        windowTimer?.invalidate()
        windowTimer = Timer.scheduledTimer(withTimeInterval: Double(chordWindowMs) / 1000.0, repeats: false) { [weak self] _ in
            self?.windowExpired()
        }

        return .deferred
    }

    /// Notify the detector that a button was released.
    public func handleRelease(_ elementName: String) {
        pressedChordElements.remove(elementName)
    }

    /// Reset runtime state while preserving chord configuration (called on profile switch).
    public func reset() {
        windowTimer?.invalidate()
        windowTimer = nil
        pressedChordElements.removeAll()
        pendingPresses.removeAll()
    }

    private func windowExpired() {
        windowTimer = nil
        let presses = pendingPresses
        pendingPresses.removeAll()

        for element in presses {
            onDeferredPress?(element)
        }
    }
}
