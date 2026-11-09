import AppKit
import SwiftUI

enum Theme: String, CaseIterable, Identifiable {
    case monochrome = "Black & White"
    case cream = "Cream"
    case coffee = "Coffee"
    case lavender = "Lavender"
    case mint = "Mint"
    case pink = "Pink"
    case sky = "Sky"

    var id: String { rawValue }

    var background: Color {
        switch self {
        case .monochrome: return .white
        case .cream: return Color(red: 1.0, green: 0.96, blue: 0.90)
        case .coffee: return Color(red: 0.82, green: 0.71, blue: 0.60)
        case .lavender: return Color(red: 0.94, green: 0.92, blue: 0.99)
        case .mint: return Color(red: 0.89, green: 0.96, blue: 0.92)
        case .pink: return Color(red: 1.0, green: 0.91, blue: 0.94)
        case .sky: return Color(red: 0.90, green: 0.95, blue: 0.99)
        }
    }

    var text: Color {
        switch self {
        case .monochrome: return .black
        case .cream: return Color(red: 0.32, green: 0.20, blue: 0.14)
        case .coffee: return Color(red: 0.22, green: 0.12, blue: 0.08)
        case .lavender: return Color(red: 0.39, green: 0.32, blue: 0.51)
        case .mint: return Color(red: 0.25, green: 0.40, blue: 0.33)
        case .pink: return Color(red: 0.52, green: 0.28, blue: 0.35)
        case .sky: return Color(red: 0.26, green: 0.36, blue: 0.48)
        }
    }
}

final class TimerModel: ObservableObject {
    @Published private(set) var state: TimerState
    @Published var compact = false
    @Published var floating = true
    @Published var showConfiguration = false
    @Published var theme: Theme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") }
    }
    private var ticker: Timer?

    init() {
        let defaults = UserDefaults.standard
        theme = Theme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .cream
        let focus = defaults.integer(forKey: "focusMinutes")
        let rest = defaults.integer(forKey: "breakMinutes")
        state = TimerState(
            focusMinutes: (1...180).contains(focus) ? focus : 25,
            breakMinutes: (1...180).contains(rest) ? rest : 5
        )
        ticker = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    var timeText: String {
        let seconds = max(0, Int(ceil(state.remaining)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    func toggleTimer() {
        if state.isRunning {
            let oldPhase = state.phase
            state.pause(at: Date())
            if state.phase != oldPhase { NSSound.beep() }
        } else {
            state.start(at: Date())
        }
    }

    func reset() {
        state.reset()
    }

    func setDuration(_ minutes: Int, for phase: Phase) {
        guard !state.isRunning, (1...180).contains(minutes) else { return }
        state.setDuration(minutes, for: phase)
        UserDefaults.standard.set(minutes, forKey: phase == .focus ? "focusMinutes" : "breakMinutes")
    }

    private func tick() {
        if state.update(at: Date()) {
            NSSound.beep()
        }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct TimerView: View {
    @ObservedObject var model: TimerModel
    var onFullHeightChange: (CGFloat) -> Void

    var body: some View {
        Group {
            if model.compact {
                compactView
            } else {
                fullView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundColor(model.theme.text)
        .tint(model.theme.text)
        .background(model.theme.background)
        .environment(\.colorScheme, .light)
        .onPreferenceChange(ContentHeightKey.self) { height in
            if height > 0 {
                onFullHeightChange(height)
            }
        }
    }

    private var fullView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    model.compact = true
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                }
                .help("Switch to compact view")
            }
            .padding(.bottom, 8)

            Text(model.state.phase.title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(model.theme.text.opacity(0.8))
            Text(model.timeText)
                .font(.system(size: 64, weight: .medium, design: .rounded).monospacedDigit())
                .padding(.vertical, 7)
                .accessibilityLabel("\(model.state.phase.title), \(model.timeText) remaining")

            HStack(spacing: 10) {
                Button(model.state.isRunning ? "Pause" : "Start") {
                    model.toggleTimer()
                }
                .keyboardShortcut(.space, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Button("Reset") { model.reset() }
                    .controlSize(.large)
                    .help("Reset the current phase")
            }

            Divider().padding(.vertical, 10)

            DisclosureGroup("Settings", isExpanded: $model.showConfiguration) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 20) {
                        durationControl("Focus", phase: .focus, value: model.state.focusMinutes)
                        durationControl("Break", phase: .rest, value: model.state.breakMinutes)
                    }
                    .disabled(model.state.isRunning)
                    if model.state.isRunning {
                        Text("Pause the timer to change durations.")
                            .font(.caption)
                            .foregroundStyle(model.theme.text.opacity(0.7))
                    }
                    Picker("Theme", selection: $model.theme) {
                        ForEach(Theme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.top, 4)
                }
                .padding(.top, 8)
            }
            .transaction { $0.animation = nil }

            HStack {
                Toggle("Keep on top", isOn: $model.floating)
                    .toggleStyle(.checkbox)
                Spacer()
            }
            .padding(.top, 10)
        }
        .padding(16)
        .fixedSize(horizontal: false, vertical: true)
        .background(GeometryReader { proxy in
            Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
        })
    }

    private func durationControl(_ title: String, phase: Phase, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(model.theme.text.opacity(0.7))
            Stepper("\(value) min", value: Binding(
                get: { phase == .focus ? model.state.focusMinutes : model.state.breakMinutes },
                set: { model.setDuration($0, for: phase) }
            ), in: 1...180)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compactView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.state.phase.title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(model.theme.text.opacity(0.8))
                Text(model.timeText)
                    .font(.system(size: 28, weight: .medium, design: .rounded).monospacedDigit())
            }
            Spacer(minLength: 0)
            Button {
                model.toggleTimer()
            } label: {
                Image(systemName: model.state.isRunning ? "pause.fill" : "play.fill")
                    .frame(width: 18)
            }
            .help(model.state.isRunning ? "Pause" : "Start")
            Button {
                model.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .help("Reset the current phase")
            Button {
                model.compact = false
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
            .help("Expand")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = TimerModel()
    private var window: NSWindow!
    private var fullHeight: CGFloat = 300
    private var observations: [Any] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pomodoro"
        let hostingView = NSHostingView(rootView: TimerView(model: model) { [weak self] height in
            guard let self else { return }
            self.fullHeight = ceil(height)
            if !self.model.compact {
                self.resizeWindow()
            }
        })
        hostingView.sizingOptions = []
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        observations.append(model.$floating.dropFirst().sink { [weak self] floating in
            self?.window.level = floating ? .floating : .normal
        })
        observations.append(model.$compact.dropFirst().sink { [weak self] compact in
            self?.resizeWindow(compact: compact)
        })
    }

    private func resizeWindow(compact: Bool? = nil) {
        let compact = compact ?? model.compact
        let size = compact ? NSSize(width: 300, height: 82) : NSSize(width: 360, height: fullHeight)
        let frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: size))
        let oldFrame = window.frame
        guard oldFrame.size != frame.size else { return }
        let newFrame = NSRect(x: oldFrame.minX, y: oldFrame.maxY - frame.height,
                              width: frame.width, height: frame.height)
        let constrainedFrame = window.constrainFrameRect(newFrame, to: window.screen)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(constrainedFrame, display: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
