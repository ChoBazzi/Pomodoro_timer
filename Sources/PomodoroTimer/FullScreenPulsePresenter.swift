import AppKit

@MainActor
final class FullScreenPulsePresenter {
    static let shared = FullScreenPulsePresenter()

    private var windows: [NSWindow] = []
    private var closeTask: Task<Void, Never>?

    private init() {}

    func show(color: NSColor) {
        closeTask?.cancel()
        closeExistingWindows()

        let screens = NSScreen.screens.isEmpty ? [NSScreen.main].compactMap { $0 } : NSScreen.screens
        windows = screens.map { screen in
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )

            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .statusBar
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.contentView = PulseOverlayView(color: color)
            window.alphaValue = 1
            window.orderFrontRegardless()

            return window
        }

        closeTask = Task {
            try? await Task.sleep(nanoseconds: 420_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.closeExistingWindows()
            }
        }
    }

    private func closeExistingWindows() {
        closeTask?.cancel()
        closeTask = nil
        windows.forEach { window in
            window.orderOut(nil)
            window.contentView = nil
        }
        windows.removeAll()
    }
}

private final class PulseOverlayView: NSView {
    private let color: NSColor

    init(color: NSColor) {
        self.color = color
        super.init(frame: .zero)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = bounds
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let radius = max(bounds.width, bounds.height) * 0.78
        let colors = [
            color.withAlphaComponent(0.22).cgColor,
            color.withAlphaComponent(0.10).cgColor,
            NSColor.clear.cgColor
        ] as CFArray
        let locations: [CGFloat] = [0, 0.48, 1]

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: locations
        ) else {
            return
        }

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: [.drawsAfterEndLocation]
        )

        context.setStrokeColor(color.withAlphaComponent(0.38).cgColor)
        context.setLineWidth(8)
        context.stroke(bounds.insetBy(dx: 4, dy: 4))
    }
}
