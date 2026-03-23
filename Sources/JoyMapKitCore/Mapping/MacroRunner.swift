import Foundation
import Logging

/// Executes sequential macro actions with delays and support for cancellation and repeat.
public final class MacroRunner {
    private let actionDispatcher: ActionDispatching
    private let logger = Logger(label: "com.joymapkit.macro")

    /// Currently running macro tasks, keyed by an identifier.
    private var runningTasks: [String: Task<Void, Never>] = [:]

    public init(actionDispatcher: ActionDispatching) {
        self.actionDispatcher = actionDispatcher
    }

    /// Start executing a macro. Cancels any previously running macro with the same key.
    /// - Parameters:
    ///   - macro: The macro action to execute.
    ///   - key: Unique key to identify this macro run (typically the element name that triggered it).
    public func start(_ macro: ActionConfig.MacroAction, key: String) {
        cancel(key: key)

        let dispatcher = actionDispatcher
        let logger = self.logger

        runningTasks[key] = Task { [weak self] in
            do {
                for _ in 0..<max(macro.repeatCount, 1) {
                    try Task.checkCancellation()

                    for step in macro.steps {
                        try Task.checkCancellation()
                        try dispatcher.dispatch(step.action, pressed: true)

                        if let holdMs = step.holdMs, holdMs > 0 {
                            try await Task.sleep(nanoseconds: UInt64(holdMs) * 1_000_000)
                        }

                        try Task.checkCancellation()
                        try dispatcher.dispatch(step.action, pressed: false)

                        if step.delayMs > 0 {
                            try await Task.sleep(nanoseconds: UInt64(step.delayMs) * 1_000_000)
                        }
                    }
                }
            } catch is CancellationError {
                logger.debug("Macro '\(macro.name ?? key)' cancelled")
            } catch {
                logger.error("Macro '\(macro.name ?? key)' failed: \(error)")
            }

            // Clean up self-reference
            _ = await MainActor.run { [weak self] in
                self?.runningTasks.removeValue(forKey: key)
            }
        }
    }

    /// Cancel a running macro by key.
    public func cancel(key: String) {
        runningTasks[key]?.cancel()
        runningTasks.removeValue(forKey: key)
    }

    /// Cancel all running macros.
    public func cancelAll() {
        for (_, task) in runningTasks {
            task.cancel()
        }
        runningTasks.removeAll()
    }
}
