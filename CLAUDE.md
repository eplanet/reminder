# Reminder - Claude Code Instructions

## Workflow Rules

- **Always update README.md and CLAUDE.md** after implementing any feature change, bug fix, or architectural modification. Keep both files in sync with the current state of the project.

## Project Overview

A macOS-only menu bar app (Swift + SwiftUI) that lets users quickly create reminders with natural language time input. Clicking the bell icon in the system tray opens a popover to enter a note and a free-form time, then fires an osascript notification with sound when the time is reached.

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
- **AppDelegate.swift** — Minimal app delegate, `applicationDidFinishLaunching` only
- **PopoverView.swift** — SwiftUI popover: multi-line input (Enter to submit), upcoming/past reminders list with edit/copy/delete, clickable URLs via `LinkedText`, settings gear button, quit button
- **SettingsView.swift** — Settings popover: sound picker (system sounds, custom MP3, silent), archive preference toggle, auto-mark expired toggle
- **DateParser.swift** — Parses free-form time strings: relative (`in 2h`, `in 30m`) via regex, absolute (`tomorrow at 9am`) via `NSDataDetector`
- **ReminderManager.swift** — Core logic: schedules `DispatchSourceTimer` per reminder, plays selected sound (NSSound/AVAudioPlayer/silent), triggers osascript notification, persists to disk, supports edit/archive/delete
- **ReminderModel.swift** — `Codable` struct: `id: UUID`, `note: String`, `fireDate: Date`, `fired: Bool`, `archived: Bool`

## Key Design Decisions

- **No `UNUserNotificationCenter`** — Unreliable for unsigned/debug apps. Uses `DispatchSourceTimer` + `osascript` notification banner instead.
- **`DispatchSourceTimer` over `Timer`** — Doesn't depend on the run loop being ready during SwiftUI initialization.
- **`LSUIElement = true`** in Info.plist — App has no dock icon, menu bar only.
- **Sound options** — 14 macOS system sounds via `NSSound`, custom MP3 via `AVAudioPlayer`, or silent mode. Selection persisted in UserDefaults.
- **Archive vs delete** — User preference: deleted reminders can be archived (`archived: true` in JSON) or permanently removed.

## Persistence

- Reminders stored as pretty-printed JSON with ISO 8601 dates at `~/.local/reminder/reminders.json`
- Fields: `id`, `note`, `fireDate`, `fired`, `archived` (backward-compatible: missing `archived` defaults to `false`)
- Sound preference stored in UserDefaults under key `reminder_sound`
- Archive preference stored in UserDefaults under key `reminder_archive_on_delete`
- Auto-mark expired preference stored in UserDefaults under key `reminder_auto_mark_expired`

## License

GPL v3
