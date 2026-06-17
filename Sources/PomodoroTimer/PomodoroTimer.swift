import Combine
import Foundation
import AppKit

@MainActor
final class PomodoroTimer: ObservableObject {
    enum SessionKind: String, CaseIterable, Identifiable {
        case focus
        case shortBreak
        case longBreak

        var id: String { rawValue }

        var title: String {
            switch self {
            case .focus:
                "Focus"
            case .shortBreak:
                "Short Break"
            case .longBreak:
                "Long Break"
            }
        }

        var nextButtonTitle: String {
            switch self {
            case .focus:
                "Finish Focus"
            case .shortBreak, .longBreak:
                "Finish Break"
            }
        }
    }

    @Published private(set) var session: SessionKind = .focus
    @Published private(set) var secondsRemaining: Int
    @Published private(set) var isRunning = false
    @Published private(set) var completedFocusSessions = 0

    @Published var settings: TimerSettings {
        didSet {
            settings.save()
            reset()
        }
    }

    private var ticker: Timer?

    init(settings: TimerSettings = .saved()) {
        self.settings = settings
        self.secondsRemaining = settings.focusMinutes * 60
    }

    var totalSecondsForCurrentSession: Int {
        duration(for: session)
    }

    var progress: Double {
        let total = max(totalSecondsForCurrentSession, 1)
        return 1 - (Double(secondsRemaining) / Double(total))
    }

    var formattedTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var cycleLabel: String {
        "Round \(completedFocusSessions % settings.focusSessionsBeforeLongBreak + 1) of \(settings.focusSessionsBeforeLongBreak)"
    }

    func toggleRunning() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    func pause() {
        isRunning = false
        ticker?.invalidate()
        ticker = nil
    }

    func reset() {
        pause()
        secondsRemaining = duration(for: session)
    }

    func resetAll() {
        pause()
        session = .focus
        completedFocusSessions = 0
        secondsRemaining = duration(for: .focus)
    }

    func completeCurrentSession() {
        let shouldContinueRunning = isRunning
        pause()
        advanceSession()
        NotificationCenter.default.post(name: .timerSessionChanged, object: session)
        playCompletionFeedback()

        if shouldContinueRunning {
            start()
        }
    }

    func setSession(_ newSession: SessionKind) {
        session = newSession
        reset()
    }

    private func tick() {
        guard secondsRemaining > 0 else {
            completeCurrentSession()
            return
        }

        secondsRemaining -= 1

        if secondsRemaining == 0 {
            completeCurrentSession()
        }
    }

    private func advanceSession() {
        switch session {
        case .focus:
            completedFocusSessions += 1
            let shouldTakeLongBreak = completedFocusSessions % settings.focusSessionsBeforeLongBreak == 0
            session = shouldTakeLongBreak ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            session = .focus
        }

        secondsRemaining = duration(for: session)
    }

    private func duration(for session: SessionKind) -> Int {
        let minutes = switch session {
        case .focus:
            settings.focusMinutes
        case .shortBreak:
            settings.shortBreakMinutes
        case .longBreak:
            settings.longBreakMinutes
        }

        return max(minutes, 1) * 60
    }

    private func playCompletionFeedback() {
        NSSound.beep()
        NSApplication.shared.requestUserAttention(.informationalRequest)
    }
}
