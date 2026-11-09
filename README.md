# Pomodoro

A small, local macOS timer. Open `Pomodoro.app` to use it; no account or server is needed.

- Start or pause with the button (or the space bar in the full view). Reset resets the current phase.
- A focus session automatically starts a break. At the end of the break, the next focus session is ready to start. The app plays a sound when a phase ends.
- Use the arrow button to switch between the full and compact views. "Keep on top" makes the window float above normal windows.
- Expand "Settings" and pause the timer to adjust the focus and break lengths, from 1 to 180 minutes. Changing the current phase's duration resets that phase.
- Choose a background and text color combination under "Settings". Cream is the default; Coffee, Black & White, Pink, and other themes are also available. Your theme and duration settings are saved on this Mac.
- The yellow window button minimizes to the Dock. Closing the window quits the app; an active timer does not continue after quitting.

The timer uses the clock rather than counting ticks, so it catches up after sleep. If the Mac sleeps through the entire break, the next focus session is ready when it wakes. The completion sound plays when the app next runs, not while the Mac is asleep.

## Rebuild

With Xcode or the Xcode command line tools installed, run `bash build.sh`. The app is created at `build/Pomodoro.app`; copy it wherever you like.
