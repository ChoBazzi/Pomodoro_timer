import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var timer: PomodoroTimer
    @State private var isHovering = false
    @State private var isSettingsOpen = false

    private let compactSize = NSSize(width: 164, height: 164)
    private let hoverSize = NSSize(width: 252, height: 164)
    private let expandedSize = NSSize(width: 380, height: 450)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.36), lineWidth: 1.4)
                )
                .shadow(color: .black.opacity(0.22), radius: 18, y: 8)

            Group {
                if isSettingsOpen {
                    VStack(spacing: 18) {
                        expandedHeader
                        expandedSettings
                    }
                } else {
                    compactWidget
                }
            }
            .padding(isSettingsOpen ? 20 : 12)
        }
        .frame(width: currentSize.width, height: currentSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(Color.clear)
        .onHover { hovering in
            guard !isSettingsOpen else { return }
            isHovering = hovering
        }
        .onChange(of: isHovering) { _, _ in
            guard !isSettingsOpen else { return }
            publishWindowSizeAfterLayout()
        }
        .onChange(of: isSettingsOpen) { _, isOpen in
            if isOpen {
                isHovering = true
            } else {
                isHovering = false
            }
            publishWindowSizeAfterLayout()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSettings)) { _ in
            isSettingsOpen.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .timerSessionChanged)) { _ in
            FullScreenPulsePresenter.shared.show(color: pulseColor)
        }
    }

    private var compactWidget: some View {
        HStack(spacing: 10) {
            circularTimer(size: 138)

            if isHovering {
                VStack(spacing: 8) {
                    settingsButton
                        .frame(width: 32, height: 32)
                    switchButton
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var expandedHeader: some View {
        HStack(spacing: 12) {
            circularTimer(size: 74)

            VStack(alignment: .leading, spacing: 3) {
                Text(timer.session.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                Text("\(timer.formattedTime) - \(timer.isRunning ? "Running" : "Paused")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            settingsButton
        }
    }

    private func circularTimer(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))

            Circle()
                .stroke(Color.secondary.opacity(0.16), lineWidth: size > 100 ? 8 : 5)

            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(
                    timerColor,
                    style: StrokeStyle(lineWidth: size > 100 ? 8 : 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: timer.progress)

            VStack(spacing: 4) {
                if isHovering && !isSettingsOpen {
                    Button {
                        timer.toggleRunning()
                    } label: {
                        Text(timer.isRunning ? "Stop" : "Start")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(timerColor)
                            .frame(width: size * 0.74, height: size * 0.42)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.space, modifiers: [])
                } else {
                    Text(timer.formattedTime)
                        .font(.system(size: size > 100 ? 28 : 18, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .lineLimit(1)
                }

                Text(timer.session.title)
                    .font(.system(size: size > 100 ? 11 : 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: size, height: size)
    }

    private var switchButton: some View {
        Button {
            timer.completeCurrentSession()
        } label: {
            Image(systemName: "forward.end.fill")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .help(timer.session.nextButtonTitle)
    }

    private var settingsButton: some View {
        Button {
            isSettingsOpen.toggle()
        } label: {
            Image(systemName: isSettingsOpen ? "xmark" : "gearshape.fill")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .help(isSettingsOpen ? "Close Settings" : "Settings")
    }

    private var expandedSettings: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Button {
                    timer.toggleRunning()
                } label: {
                    Label(timer.isRunning ? "Stop" : "Start", systemImage: timer.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    timer.completeCurrentSession()
                } label: {
                    Label("Switch", systemImage: "forward.end.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Picker("Session", selection: Binding(
                get: { timer.session },
                set: { timer.setSession($0) }
            )) {
                ForEach(PomodoroTimer.SessionKind.allCases) { session in
                    Text(session.title).tag(session)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 14) {
                settingsStepper(title: "Focus", value: settingsBinding(\.focusMinutes), range: 1...120, suffix: "min")
                settingsStepper(title: "Short Break", value: settingsBinding(\.shortBreakMinutes), range: 1...60, suffix: "min")
                settingsStepper(title: "Long Break", value: settingsBinding(\.longBreakMinutes), range: 1...120, suffix: "min")
                settingsStepper(title: "Long Break After", value: settingsBinding(\.focusSessionsBeforeLongBreak), range: 1...12, suffix: "rounds")
            }

            HStack(spacing: 10) {
                Button {
                    timer.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    timer.resetAll()
                } label: {
                    Label("Reset All", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func settingsStepper(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        suffix: String
    ) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                Text("\(value.wrappedValue) \(suffix)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private func settingsBinding(_ keyPath: WritableKeyPath<TimerSettings, Int>) -> Binding<Int> {
        Binding(
            get: {
                timer.settings[keyPath: keyPath]
            },
            set: { newValue in
                var settings = timer.settings
                settings[keyPath: keyPath] = newValue
                timer.settings = settings
            }
        )
    }

    private var currentSize: NSSize {
        switch currentMode {
        case .settings:
            expandedSize
        case .hover:
            hoverSize
        case .compact:
            compactSize
        }
    }

    private var currentMode: TimerWindowMode {
        if isSettingsOpen {
            .settings
        } else if isHovering {
            .hover
        } else {
            .compact
        }
    }

    private var timerColor: Color {
        switch timer.session {
        case .focus:
            Color(red: 0.88, green: 0.24, blue: 0.22)
        case .shortBreak:
            Color(red: 0.13, green: 0.58, blue: 0.45)
        case .longBreak:
            Color(red: 0.18, green: 0.38, blue: 0.72)
        }
    }

    private var pulseColor: NSColor {
        switch timer.session {
        case .focus:
            NSColor(calibratedRed: 0.88, green: 0.24, blue: 0.22, alpha: 1)
        case .shortBreak:
            NSColor(calibratedRed: 0.13, green: 0.58, blue: 0.45, alpha: 1)
        case .longBreak:
            NSColor(calibratedRed: 0.18, green: 0.38, blue: 0.72, alpha: 1)
        }
    }

    private func publishWindowSizeAfterLayout() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .timerWindowSizeChanged,
                object: nil,
                userInfo: [
                    "width": currentSize.width,
                    "height": currentSize.height,
                    "mode": currentMode.rawValue
                ]
            )
        }
    }
}

private enum TimerWindowMode: String {
    case compact
    case hover
    case settings
}
