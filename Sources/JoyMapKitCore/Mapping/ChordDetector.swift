import Foundation

/// Detects simultaneous button presses within a configurable time window.
/// Phase 4 implementation — basic placeholder for now.
public final class ChordDetector {
    public var chordWindowMs: Int

    public init(chordWindowMs: Int = 50) {
        self.chordWindowMs = chordWindowMs
    }
}
