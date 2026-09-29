import Foundation
import Logging

/// Executes sequential macro actions with delays and support for cancellation and repeat.
/// - Important: All methods must be called from the main thread to avoid data races on `runningTasks`.
public final class MacroRunner {
    private let actionDispatcher: ActionDispatching
    private let logger = Logger(label: "com.joymapkit.macro")

    private final class RunningMacro {
        var task: Task<Void, Never>?
        var heldAction: ActionConfig?
    }

    /// Currently running macros, including the action each one must release on cancellation.
    private var runningTasks: [String: RunningMacro] = [:]

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
        let run = RunningMacro()
        runningTasks[key] = run

        run.task = Task { @MainActor [weak self] in
            defer {
                do { try Self.releaseHeldAction(run, dispatcher: dispatcher) }
                catch { logger.error("Macro release failed: \(error)") }
                // An older cancelled task must not remove its replacement.
                if self?.runningTasks[key] === run {
                    self?.runningTasks.removeValue(forKey: key)
                }
            }
            do {
                for _ in 0..<max(macro.repeatCount, 1) {
                    try Task.checkCancellation()

                    for step in macro.steps {
                        try Task.checkCancellation()
                        try dispatcher.dispatch(step.action, pressed: true)
                        run.heldAction = step.action

                        if let holdMs = step.holdMs, holdMs > 0 {
                            try await Task.sleep(nanoseconds: UInt64(holdMs) * 1_000_000)
                        }

                        try Task.checkCancellation()
                        try Self.releaseHeldAction(run, dispatcher: dispatcher)

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
        }
    }

    /// Cancel a running macro by key.
    public func cancel(key: String) {
        guard let run = runningTasks.removeValue(forKey: key) else { return }
        run.task?.cancel()
        do { try Self.releaseHeldAction(run, dispatcher: actionDispatcher) }
        catch { logger.error("Macro release failed: \(error)") }
    }

    /// Cancel all running macros.
    public func cancelAll() {
        for key in Array(runningTasks.keys) {
            cancel(key: key)
        }
    }

    private static func releaseHeldAction(_ run: RunningMacro, dispatcher: ActionDispatching) throws {
        guard let action = run.heldAction else { return }
        run.heldAction = nil
        try dispatcher.dispatch(action, pressed: false)
    }
}
