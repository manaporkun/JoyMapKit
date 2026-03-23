import SwiftUI
import GameController
import AppKit
import AudioToolbox
import JoyMapKitCore

// MARK: - Sound Effects

/// Uses AudioToolbox for zero-latency system sounds. Sounds are pre-loaded at init.
private final class SoundFX {
    static let shared = SoundFX()

    private var hitSound: SystemSoundID = 0
    private var missSound: SystemSoundID = 0
    private var countdownSound: SystemSoundID = 0
    private var startSound: SystemSoundID = 0
    private var gameOverSound: SystemSoundID = 0
    private var comboBreakSound: SystemSoundID = 0

    private init() {
        hitSound = loadSystemSound("/System/Library/Sounds/Glass.aiff")
        missSound = loadSystemSound("/System/Library/Sounds/Basso.aiff")
        countdownSound = loadSystemSound("/System/Library/Sounds/Pop.aiff")
        startSound = loadSystemSound("/System/Library/Sounds/Purr.aiff")
        gameOverSound = loadSystemSound("/System/Library/Sounds/Sosumi.aiff")
        comboBreakSound = loadSystemSound("/System/Library/Sounds/Funk.aiff")
    }

    deinit {
        for id in [hitSound, missSound, countdownSound, startSound, gameOverSound, comboBreakSound] where id != 0 {
            AudioServicesDisposeSystemSoundID(id)
        }
    }

    private func loadSystemSound(_ path: String) -> SystemSoundID {
        var soundID: SystemSoundID = 0
        let url = URL(fileURLWithPath: path) as CFURL
        AudioServicesCreateSystemSoundID(url, &soundID)
        return soundID
    }

    func playHit()        { AudioServicesPlaySystemSound(hitSound) }
    func playMiss()       { AudioServicesPlaySystemSound(missSound) }
    func playCountdown()  { AudioServicesPlaySystemSound(countdownSound) }
    func playStart()      { AudioServicesPlaySystemSound(startSound) }
    func playGameOver()   { AudioServicesPlaySystemSound(gameOverSound) }
    func playComboBreak() { AudioServicesPlaySystemSound(comboBreakSound) }
}

// MARK: - Game Types

private enum GameState {
    case idle, countdown, playing, gameOver
}

private struct ButtonPrompt: Equatable {
    let elementName: String
    let displayName: String
    let sfSymbol: String
    let color: Color

    static let allPrompts: [ButtonPrompt] = [
        ButtonPrompt(elementName: "Button A", displayName: "Button A", sfSymbol: "a.circle.fill", color: .green),
        ButtonPrompt(elementName: "Button B", displayName: "Button B", sfSymbol: "b.circle.fill", color: .red),
        ButtonPrompt(elementName: "Button X", displayName: "Button X", sfSymbol: "x.circle.fill", color: .blue),
        ButtonPrompt(elementName: "Button Y", displayName: "Button Y", sfSymbol: "y.circle.fill", color: .yellow),
        ButtonPrompt(elementName: "Left Shoulder", displayName: "Left Shoulder", sfSymbol: "l.rectangle.roundedbottom", color: .purple),
        ButtonPrompt(elementName: "Right Shoulder", displayName: "Right Shoulder", sfSymbol: "r.rectangle.roundedbottom", color: .purple),
        ButtonPrompt(elementName: "Direction Pad Up", displayName: "D-Pad Up", sfSymbol: "arrow.up.circle.fill", color: .orange),
        ButtonPrompt(elementName: "Direction Pad Down", displayName: "D-Pad Down", sfSymbol: "arrow.down.circle.fill", color: .orange),
        ButtonPrompt(elementName: "Direction Pad Left", displayName: "D-Pad Left", sfSymbol: "arrow.left.circle.fill", color: .orange),
        ButtonPrompt(elementName: "Direction Pad Right", displayName: "D-Pad Right", sfSymbol: "arrow.right.circle.fill", color: .orange),
    ]

    /// All element names that count as valid input for matching.
    static let validElementNames: Set<String> = Set(allPrompts.map(\.elementName))
}

private enum FeedbackType {
    case hit, miss
}

// MARK: - View Model

@MainActor
private final class RhythmGameViewModel: ObservableObject {
    // Game configuration
    static let totalPrompts = 30
    static let maxMisses = 5
    static let initialTempo: Double = 2.0
    static let tempoDecrement: Double = 0.05
    static let minimumTempo: Double = 0.5
    static let pressThreshold: Float = 0.5

    // State
    @Published var gameState: GameState = .idle
    @Published var currentPrompt: ButtonPrompt = ButtonPrompt.allPrompts[0]
    @Published var score: Int = 0
    @Published var combo: Int = 0
    @Published var bestCombo: Int = 0
    @Published var totalHits: Int = 0
    @Published var totalMisses: Int = 0
    @Published var promptIndex: Int = 0
    @Published var tempo: Double = initialTempo
    @Published var timeRemaining: Double = 1.0 // Normalized 0..1
    @Published var countdownNumber: Int = 3
    @Published var feedback: FeedbackType?
    @Published var promptTransitionID: UUID = UUID()
    @Published var controllerConnected: Bool = false

    let controllerManager = ControllerManager(enableBackgroundMonitoring: false)

    private var promptTimer: Timer?
    private var tickTimer: Timer?
    private var countdownTimer: Timer?
    private var feedbackResetTask: Task<Void, Never>?
    private var promptDeadline: Date = .distantFuture

    /// Tracks which elements are currently held down to avoid repeated triggers.
    private var heldElements: Set<String> = []

    /// Whether the current prompt has already been answered (prevents double-scoring).
    private var currentPromptAnswered: Bool = false

    func start() {
        controllerManager.startMonitoring()
        controllerManager.onInputChanged = { [weak self] _, elementName, value in
            Task { @MainActor in
                self?.handleInput(elementName: elementName, value: value)
            }
        }
        controllerManager.onControllerConnected = { [weak self] _ in
            Task { @MainActor in
                self?.controllerConnected = true
            }
        }
        controllerManager.onControllerDisconnected = { [weak self] _ in
            Task { @MainActor in
                self?.controllerConnected = !(self?.controllerManager.connectedControllers.isEmpty ?? true)
            }
        }
        controllerConnected = !controllerManager.connectedControllers.isEmpty
    }

    func stop() {
        invalidateAllTimers()
        controllerManager.stopMonitoring()
    }

    // MARK: - Input Handling

    private func handleInput(elementName: String, value: Float) {
        let isPressed = value > Self.pressThreshold

        if !isPressed {
            heldElements.remove(elementName)
            return
        }

        // Only react to fresh presses of valid buttons.
        guard isPressed,
              ButtonPrompt.validElementNames.contains(elementName),
              !heldElements.contains(elementName) else { return }

        heldElements.insert(elementName)

        switch gameState {
        case .idle:
            beginCountdown()
        case .playing:
            evaluatePress(elementName: elementName)
        case .countdown, .gameOver:
            break
        }
    }

    // MARK: - Countdown

    private func beginCountdown() {
        gameState = .countdown
        countdownNumber = 3

        SoundFX.shared.playCountdown()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self else { timer.invalidate(); return }
                self.countdownNumber -= 1
                if self.countdownNumber < 0 {
                    timer.invalidate()
                    self.countdownTimer = nil
                    SoundFX.shared.playStart()
                    self.beginPlaying()
                } else {
                    SoundFX.shared.playCountdown()
                }
            }
        }
    }

    // MARK: - Game Loop

    private func beginPlaying() {
        score = 0
        combo = 0
        bestCombo = 0
        totalHits = 0
        totalMisses = 0
        promptIndex = 0
        tempo = Self.initialTempo
        gameState = .playing
        presentNextPrompt()
    }

    private func presentNextPrompt() {
        guard promptIndex < Self.totalPrompts, totalMisses < Self.maxMisses else {
            endGame()
            return
        }

        currentPromptAnswered = false

        // Pick a random prompt different from the current one.
        var next: ButtonPrompt
        repeat {
            next = ButtonPrompt.allPrompts.randomElement()!
        } while next == currentPrompt && ButtonPrompt.allPrompts.count > 1

        currentPrompt = next
        promptTransitionID = UUID()
        timeRemaining = 1.0
        promptDeadline = Date().addingTimeInterval(tempo)

        // Tick timer to animate the countdown bar (~60fps).
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self else { timer.invalidate(); return }
                let remaining = self.promptDeadline.timeIntervalSinceNow
                if remaining <= 0 {
                    self.timeRemaining = 0
                    timer.invalidate()
                    self.tickTimer = nil
                    self.onTimeout()
                } else {
                    self.timeRemaining = remaining / self.tempo
                }
            }
        }
    }

    // MARK: - Evaluation

    private func evaluatePress(elementName: String) {
        guard !currentPromptAnswered else { return }
        currentPromptAnswered = true
        tickTimer?.invalidate()
        tickTimer = nil

        if elementName == currentPrompt.elementName {
            onHit()
        } else {
            onMiss()
        }
    }

    private func onHit() {
        combo += 1
        bestCombo = max(bestCombo, combo)
        totalHits += 1
        score += 10 * max(combo, 1)
        tempo = max(Self.minimumTempo, tempo - Self.tempoDecrement)
        showFeedback(.hit)
        SoundFX.shared.playHit()
        advancePrompt()
    }

    private func onMiss() {
        let hadCombo = combo > 3
        combo = 0
        totalMisses += 1
        showFeedback(.miss)
        if hadCombo {
            SoundFX.shared.playComboBreak()
        } else {
            SoundFX.shared.playMiss()
        }
        advancePrompt()
    }

    private func onTimeout() {
        guard !currentPromptAnswered else { return }
        currentPromptAnswered = true
        let hadCombo = combo > 3
        combo = 0
        totalMisses += 1
        showFeedback(.miss)
        if hadCombo {
            SoundFX.shared.playComboBreak()
        } else {
            SoundFX.shared.playMiss()
        }
        advancePrompt()
    }

    private func advancePrompt() {
        promptIndex += 1
        // Brief pause before next prompt so the feedback flash is visible.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.presentNextPrompt()
        }
    }

    private func showFeedback(_ type: FeedbackType) {
        feedback = type
        feedbackResetTask?.cancel()
        feedbackResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self?.feedback = nil
        }
    }

    private func endGame() {
        invalidateAllTimers()
        gameState = .gameOver
        SoundFX.shared.playGameOver()
    }

    func resetToIdle() {
        invalidateAllTimers()
        feedback = nil
        gameState = .idle
    }

    private func invalidateAllTimers() {
        promptTimer?.invalidate()
        promptTimer = nil
        tickTimer?.invalidate()
        tickTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        feedbackResetTask?.cancel()
        feedbackResetTask = nil
    }

    var accuracy: Double {
        let total = totalHits + totalMisses
        guard total > 0 else { return 0 }
        return Double(totalHits) / Double(total) * 100.0
    }

    var remainingLives: Int {
        max(0, Self.maxMisses - totalMisses)
    }
}

// MARK: - Main View

struct RhythmGameView: View {
    @StateObject private var vm = RhythmGameViewModel()

    var body: some View {
        ZStack {
            backgroundGradient

            switch vm.gameState {
            case .idle:
                idleView
            case .countdown:
                countdownView
            case .playing:
                playingView
            case .gameOver:
                gameOverView
            }
        }
        .frame(minWidth: 560, minHeight: 420)
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(nsColor: NSColor(white: 0.08, alpha: 1)),
                Color(nsColor: NSColor(white: 0.14, alpha: 1)),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 24) {
            PulsingSymbol(systemName: "gamecontroller.fill", fontSize: 64)
                .foregroundStyle(.white.opacity(0.7))

            Text("Rhythm Reaction")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            BlinkingText(text: "Press any button to start")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.6))

            if !vm.controllerConnected {
                Label("No controller connected", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Countdown

    private var countdownView: some View {
        VStack {
            if vm.countdownNumber > 0 {
                Text("\(vm.countdownNumber)")
                    .font(.system(size: 120, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .id(vm.countdownNumber)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 2.0).combined(with: .opacity),
                        removal: .scale(scale: 0.3).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: vm.countdownNumber)
            } else {
                Text("GO!")
                    .font(.system(size: 100, weight: .heavy, design: .rounded))
                    .foregroundStyle(.green)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: vm.countdownNumber)
    }

    // MARK: - Playing

    private var playingView: some View {
        VStack(spacing: 0) {
            // Top bar: score, lives, combo
            HStack {
                scoreLabel
                Spacer()
                livesLabel
                Spacer()
                comboLabel
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Spacer()

            // Central prompt card
            promptCard
                .id(vm.promptTransitionID)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: vm.promptTransitionID)

            Spacer()

            // Bottom: progress indicator
            Text("Prompt \(min(vm.promptIndex + 1, RhythmGameViewModel.totalPrompts)) of \(RhythmGameViewModel.totalPrompts)")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 20)
        }
    }

    private var scoreLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("SCORE")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            Text("\(vm.score)")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .animation(.easeOut(duration: 0.15), value: vm.score)
        }
        .frame(minWidth: 100, alignment: .leading)
    }

    private var livesLabel: some View {
        HStack(spacing: 4) {
            ForEach(0..<RhythmGameViewModel.maxMisses, id: \.self) { index in
                Image(systemName: index < vm.remainingLives ? "heart.fill" : "heart")
                    .foregroundStyle(index < vm.remainingLives ? .red : .white.opacity(0.25))
                    .font(.system(size: 18))
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: vm.remainingLives)
            }
        }
    }

    private var comboLabel: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("COMBO")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            HStack(spacing: 4) {
                if vm.combo > 5 {
                    Text("\u{1F525}") // fire emoji
                        .font(.system(size: 20))
                }
                Text("\(vm.combo)x")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(comboColor)
                    .animation(.easeOut(duration: 0.15), value: vm.combo)
            }
        }
        .frame(minWidth: 100, alignment: .trailing)
    }

    private var comboColor: Color {
        if vm.combo >= 10 { return .orange }
        if vm.combo >= 5 { return .yellow }
        return .white
    }

    private var promptCard: some View {
        VStack(spacing: 16) {
            Image(systemName: vm.currentPrompt.sfSymbol)
                .font(.system(size: 60))
                .foregroundStyle(vm.currentPrompt.color)
                .shadow(color: vm.currentPrompt.color.opacity(0.6), radius: 12, y: 4)

            Text(vm.currentPrompt.displayName)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Timer bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(timerBarColor)
                        .frame(width: geo.size.width * max(0, vm.timeRemaining))
                        .animation(.linear(duration: 1.0 / 60.0), value: vm.timeRemaining)
                }
            }
            .frame(height: 10)
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(width: 320)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(feedbackOverlayColor)
                        .animation(.easeOut(duration: 0.25), value: vm.feedback == nil)
                }
        }
    }

    private var timerBarColor: Color {
        if vm.timeRemaining > 0.5 { return .green }
        if vm.timeRemaining > 0.25 { return .yellow }
        return .red
    }

    private var feedbackOverlayColor: Color {
        switch vm.feedback {
        case .hit:
            return .green.opacity(0.25)
        case .miss:
            return .red.opacity(0.25)
        case nil:
            return .clear
        }
    }

    // MARK: - Game Over

    private var gameOverView: some View {
        VStack(spacing: 24) {
            Text("Game Over")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 16) {
                statRow(label: "Final Score", value: "\(vm.score)")
                statRow(label: "Best Combo", value: "\(vm.bestCombo)x")
                statRow(label: "Accuracy", value: String(format: "%.0f%%", vm.accuracy))
                statRow(label: "Hits / Misses", value: "\(vm.totalHits) / \(vm.totalMisses)")
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }

            Button(action: { vm.resetToIdle() }) {
                Label("Play Again", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .frame(width: 260)
    }
}

// MARK: - Helper Views (macOS 13 compatible animations)

/// An SF Symbol image that continuously pulses in opacity.
private struct PulsingSymbol: View {
    let systemName: String
    let fontSize: CGFloat

    @State private var isPulsed = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: fontSize))
            .opacity(isPulsed ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsed)
            .onAppear { isPulsed = true }
    }
}

/// A text view that continuously blinks in opacity.
private struct BlinkingText: View {
    let text: String

    @State private var dimmed = false

    var body: some View {
        Text(text)
            .opacity(dimmed ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: dimmed)
            .onAppear { dimmed = true }
    }
}
