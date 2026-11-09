import Foundation

@main
struct TimerStateTests {
    static func main() {
        let start = Date(timeIntervalSince1970: 1_000)
        var timer = TimerState()
        assert(timer.remaining == 1500 && timer.phase == .focus && !timer.isRunning)

        timer.start(at: start)
        timer.update(at: start.addingTimeInterval(42))
        assert(timer.remaining == 1458)
        timer.pause(at: start.addingTimeInterval(50))
        assert(timer.remaining == 1450 && !timer.isRunning)
        timer.start(at: start.addingTimeInterval(100))
        timer.update(at: start.addingTimeInterval(1550))
        assert(timer.phase == .rest && timer.isRunning && timer.remaining == 300)
        timer.update(at: start.addingTimeInterval(1600))
        assert(timer.remaining == 250)
        timer.pause(at: start.addingTimeInterval(1610))
        assert(timer.remaining == 240 && !timer.isRunning)
        timer.reset()
        assert(timer.remaining == 300 && timer.phase == .rest)

        timer.setDuration(2, for: .rest)
        assert(timer.remaining == 120)
        timer.setDuration(3, for: .focus)
        assert(timer.remaining == 120)
        timer.start(at: start)
        timer.update(at: start.addingTimeInterval(120))
        assert(timer.phase == .focus && !timer.isRunning && timer.remaining == 180)

        timer.start(at: start)
        timer.update(at: start.addingTimeInterval(200))
        assert(timer.phase == .rest && timer.isRunning && timer.remaining == 100)
        timer.update(at: start.addingTimeInterval(400))
        assert(timer.phase == .focus && !timer.isRunning && timer.remaining == 180)

        timer.start(at: start)
        timer.pause(at: start.addingTimeInterval(400))
        assert(timer.phase == .focus && !timer.isRunning && timer.remaining == 180)
        print("Timer state tests passed.")
    }
}
