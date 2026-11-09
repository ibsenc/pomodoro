import Foundation

enum Phase {
    case focus
    case rest

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .rest: return "Break"
        }
    }
}

struct TimerState {
    var focusMinutes: Int
    var breakMinutes: Int
    private(set) var phase: Phase = .focus
    private(set) var remaining: TimeInterval
    private(set) var deadline: Date?

    var isRunning: Bool { deadline != nil }

    init(focusMinutes: Int = 25, breakMinutes: Int = 5) {
        self.focusMinutes = focusMinutes
        self.breakMinutes = breakMinutes
        self.remaining = TimeInterval(focusMinutes * 60)
    }

    mutating func start(at now: Date) {
        guard deadline == nil else { return }
        deadline = now.addingTimeInterval(remaining)
    }

    mutating func pause(at now: Date) {
        update(at: now)
        guard let deadline else { return }
        remaining = max(0, deadline.timeIntervalSince(now))
        self.deadline = nil
    }

    mutating func reset() {
        deadline = nil
        remaining = duration(for: phase)
    }

    mutating func setDuration(_ minutes: Int, for phase: Phase) {
        switch phase {
        case .focus: focusMinutes = minutes
        case .rest: breakMinutes = minutes
        }
        if self.phase == phase {
            reset()
        }
    }

    // Returns true if at least one phase ended.
    @discardableResult
    mutating func update(at now: Date) -> Bool {
        guard let deadline else { return false }
        if now < deadline {
            remaining = deadline.timeIntervalSince(now)
            return false
        }

        if phase == .focus {
            phase = .rest
            let breakDeadline = deadline.addingTimeInterval(duration(for: .rest))
            if now < breakDeadline {
                self.deadline = breakDeadline
                remaining = breakDeadline.timeIntervalSince(now)
            } else {
                phase = .focus
                self.deadline = nil
                remaining = duration(for: .focus)
            }
        } else {
            phase = .focus
            self.deadline = nil
            remaining = duration(for: .focus)
        }
        return true
    }

    private func duration(for phase: Phase) -> TimeInterval {
        TimeInterval((phase == .focus ? focusMinutes : breakMinutes) * 60)
    }
}
