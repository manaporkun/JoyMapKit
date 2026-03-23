import Foundation

/// Executes sequential macro actions with delays.
/// Phase 4 implementation — basic placeholder for now.
public final class MacroRunner {
    private let actionDispatcher: ActionDispatching

    public init(actionDispatcher: ActionDispatching) {
        self.actionDispatcher = actionDispatcher
    }

    public func execute(_ macro: ActionConfig.MacroAction) async throws {
        for step in macro.steps {
            try actionDispatcher.dispatch(step.action, pressed: true)
            if let holdMs = step.holdMs, holdMs > 0 {
                try await Task.sleep(nanoseconds: UInt64(holdMs) * 1_000_000)
            }
            try actionDispatcher.dispatch(step.action, pressed: false)
            if step.delayMs > 0 {
                try await Task.sleep(nanoseconds: UInt64(step.delayMs) * 1_000_000)
            }
        }
    }

    public func cancel() {
        // Phase 4: cancel running macro via Task cancellation
    }
}
