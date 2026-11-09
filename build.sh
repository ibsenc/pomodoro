#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
app="$PWD/build/Pomodoro.app"
mkdir -p "$app/Contents/MacOS"
cp Info.plist "$app/Contents/Info.plist"
swiftc -O -target "$(uname -m)-apple-macosx13.0" TimerState.swift main.swift -o "$app/Contents/MacOS/Pomodoro"
codesign --force --deep --sign - "$app"
echo "Built $app"
