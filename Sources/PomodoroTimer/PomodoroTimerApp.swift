import AppKit
import SwiftUI

@main
enum PomodoroTimerApp {
    @MainActor private static let appDelegate = AppDelegate()

    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.delegate = appDelegate
        app.mainMenu = makeMainMenu(target: appDelegate)
        app.run()
    }

    @MainActor
    private static func makeMainMenu(target: AppDelegate) -> NSMenu {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "Quit PomodoroTimer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let timerMenuItem = NSMenuItem()
        let timerMenu = NSMenu(title: "Timer")

        let startPauseItem = NSMenuItem(
            title: "Start / Pause",
            action: #selector(AppDelegate.toggleTimer),
            keyEquivalent: " "
        )
        startPauseItem.target = target
        timerMenu.addItem(startPauseItem)

        let resetItem = NSMenuItem(
            title: "Reset",
            action: #selector(AppDelegate.resetTimer),
            keyEquivalent: "r"
        )
        resetItem.keyEquivalentModifierMask = [.command]
        resetItem.target = target
        timerMenu.addItem(resetItem)

        let skipItem = NSMenuItem(
            title: "Skip Session",
            action: #selector(AppDelegate.skipSession),
            keyEquivalent: String(UnicodeScalar(NSRightArrowFunctionKey)!)
        )
        skipItem.keyEquivalentModifierMask = [.command]
        skipItem.target = target
        timerMenu.addItem(skipItem)

        timerMenu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(AppDelegate.toggleSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = target
        timerMenu.addItem(settingsItem)

        timerMenuItem.submenu = timerMenu
        mainMenu.addItem(timerMenuItem)

        return mainMenu
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let timer = PomodoroTimer()

    private var window: NSWindow?
    private var hostingView: NSHostingView<AnyView>?
    private var sizeObserver: NSObjectProtocol?
    private var compactFrame = NSRect(x: 0, y: 0, width: 164, height: 164)
    private var windowMode = TimerWindowMode.compact
    private var isResizingProgrammatically = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = AnyView(ContentView().environmentObject(timer))
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 164, height: 164)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let containerView = RoundedWindowContentView(frame: hostingView.frame)
        containerView.autoresizesSubviews = true
        containerView.addSubview(hostingView)

        let window = FloatingTimerWindow(
            contentRect: NSRect(x: 0, y: 0, width: 164, height: 164),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.contentView = containerView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.orderFrontRegardless()
        window.makeKey()

        self.window = window
        self.hostingView = hostingView
        sizeObserver = NotificationCenter.default.addObserver(
            forName: .timerWindowSizeChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self,
                let width = notification.userInfo?["width"] as? CGFloat,
                let height = notification.userInfo?["height"] as? CGFloat,
                let modeName = notification.userInfo?["mode"] as? String,
                let mode = TimerWindowMode(rawValue: modeName)
            else {
                return
            }

            Task { @MainActor in
                self.resizeWindow(to: NSSize(width: width, height: height), mode: mode)
            }
        }

        positionWindowInBottomRight(window)
        compactFrame = window.frame
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func toggleTimer() {
        timer.toggleRunning()
    }

    @objc func resetTimer() {
        timer.reset()
    }

    @objc func skipSession() {
        timer.completeCurrentSession()
    }

    @objc func toggleSettings() {
        NotificationCenter.default.post(name: .toggleSettings, object: nil)
    }

    private func positionWindowInBottomRight(_ window: NSWindow) {
        let screen = window.screen ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let margin: CGFloat = 22
        let size = window.frame.size
        window.setFrameOrigin(NSPoint(
            x: visibleFrame.maxX - size.width - margin,
            y: visibleFrame.minY + margin
        ))
    }

    private func resizeWindow(to size: NSSize, mode: TimerWindowMode) {
        guard let window else { return }

        if windowMode == .compact {
            compactFrame = window.frame
        }

        let origin = switch mode {
        case .compact:
            compactFrame.origin
        case .hover, .settings:
            expandedOrigin(for: size, from: compactFrame, in: window)
        }

        var frame = window.frame
        frame.origin = origin
        frame.size = size

        if frame == window.frame {
            windowMode = mode
            return
        }

        isResizingProgrammatically = true
        window.setFrame(frame, display: true, animate: false)
        window.contentView?.frame = NSRect(origin: .zero, size: size)
        hostingView?.frame = NSRect(origin: .zero, size: size)
        isResizingProgrammatically = false
        windowMode = mode
    }

    private func expandedOrigin(for size: NSSize, from compactFrame: NSRect, in window: NSWindow) -> NSPoint {
        let screen = window.screen ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var origin = NSPoint(
            x: compactFrame.maxX - size.width,
            y: compactFrame.minY
        )

        origin.x = min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - size.width)
        origin.y = min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - size.height)
        return origin
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        guard let window, !isResizingProgrammatically else { return }
        compactFrame = compactFrameForCurrentWindowPosition(window)
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard let window else { return }
        compactFrame = compactFrameForCurrentWindowPosition(window)
    }

    private func compactFrameForCurrentWindowPosition(_ window: NSWindow) -> NSRect {
        let compactSize = compactFrame.size

        switch windowMode {
        case .compact:
            return NSRect(origin: window.frame.origin, size: compactSize)
        case .hover, .settings:
            return NSRect(
                x: window.frame.maxX - compactSize.width,
                y: window.frame.minY,
                width: compactSize.width,
                height: compactSize.height
            )
        }
    }
}

private enum TimerWindowMode: String {
    case compact
    case hover
    case settings
}

private final class FloatingTimerWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private final class RoundedWindowContentView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.cornerRadius = 18
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        layer?.cornerRadius = 18
    }
}

extension Notification.Name {
    static let toggleSettings = Notification.Name("toggleSettings")
    static let timerSessionChanged = Notification.Name("timerSessionChanged")
    static let timerWindowSizeChanged = Notification.Name("timerWindowSizeChanged")
}
