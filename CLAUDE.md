# Reminder - Claude Code Instructions

## Project Overview

A macOS-only menu bar app (Swift + SwiftUI) that lets users quickly create reminders with natural language time input. Clicking the bell icon in the system tray opens a popover to enter a note and a free-form time, then fires a floating alert window with sound when the time is reached.

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI with `MenuBarExtra` (macOS 13+)
- **Build system:** Swift Package Manager + Makefile
- **Target:** macOS 13 (Ventura) or later

## Build & Run

```bash
make build   # Compile and assemble .app bundle
make run     # Build + launch
make clean   # Remove build artifacts
```

**Important:** Never use `swift run` directly. The app requires a proper `.app` bundle (with `Info.plist`) for macOS system integrations. The Makefile handles assembling the bundle.

## Architecture

- **ReminderApp.swift** — `@main` entry point using `MenuBarExtra` with `.window` style
- **AppDelegate.swift** — Wires the `ReminderManager` to fire alerts via `AlertWindowController`, starts dispatch timers after app launch
- **PopoverView.swift** — SwiftUI popover: note field, time field (Enter to submit), upcoming reminders list, sound picker, quit button
- **AlertWindowController.swift** — Creates a floating `NSWindow` that appears on top of everything when a reminder fires
- **DateParser.swift** — Parses free-form time strings: relative (`in 2h`, `in 30m`) via regex, absolute (`tomorrow at 9am`) via `NSDataDetector`
- **ReminderManager.swift** — Core logic: schedules `DispatchSourceTimer` per reminder, plays selected sound, triggers osascript notification + alert window, persists to disk
- **ReminderModel.swift** — `Codable` struct: `id: UUID`, `note: String`, `fireDate: Date`

## Key Design Decisions

- **No `UNUserNotificationCenter`** — Unreliable for unsigned/debug apps. Instead uses `DispatchSourceTimer` + `NSWindow` alert + `osascript` notification banner.
- **`DispatchSourceTimer` over `Timer`** — Doesn't depend on the run loop being ready during SwiftUI initialization.
- **`LSUIElement = true`** in Info.plist — App has no dock icon, menu bar only.
- **Sound via `NSSound`** — 14 macOS system sounds available, selection persisted in UserDefaults.

## Persistence

- Reminders stored as pretty-printed JSON with ISO 8601 dates at `~/.local/reminder/reminders.json`
- Sound preference stored in UserDefaults under key `reminder_sound`

## License

GPL v3
