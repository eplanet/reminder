# Reminder

A lightweight macOS menu bar app for quickly creating reminders with natural language time input.

## Features

- **Menu bar app** — lives in your system tray as a bell icon, no dock clutter
- **Single input, Slack-style** — type everything in one field, e.g. `Buy groceries tomorrow at 9am`
- **Live preview** — see the extracted note and resolved date as you type
- **Native notifications** — macOS notification banner with sound when a reminder fires
- **Customizable sound** — pick from 14 macOS system sounds (Glass, Ping, Pop, Sosumi, etc.) with a preview button
- **Persistent reminders** — saved as JSON in `~/.local/reminder/reminders.json`, survives restarts
- **Manage reminders** — view upcoming reminders and delete them from the popover

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+

## Build & Run

```bash
# Build the .app bundle
make build

# Build and launch
make run

# Clean build artifacts
make clean
```

> **Note:** Do not use `swift run` directly — the app requires a proper `.app` bundle for macOS system integrations.

## Install

```bash
make install
```

This will:
- Build the app and copy `Reminder.app` to `~/Applications/`
- Create a LaunchAgent so the app starts automatically at login

To uninstall and remove the LaunchAgent:

```bash
make uninstall
```

## Usage

1. Click the bell icon in the menu bar — the input is auto-focused
2. Type your reminder in a single field: **what** + **when** (like Slack's `/remind`)
3. Press **Enter**
4. When the time comes, a native macOS notification appears with a sound

## Examples

| Input | Note | When |
|---|---|---|
| `Buy groceries tomorrow at 9am` | Buy groceries | Tomorrow 9:00 AM |
| `Call mom in 2h` | Call mom | 2 hours from now |
| `Team standup next Monday at 10am` | Team standup | Next Monday 10:00 AM |
| `Take a break in 30m` | Take a break | 30 minutes from now |
| `Submit report Friday at 3pm` | Submit report | This Friday 3:00 PM |

## License

[GPL v3](https://www.gnu.org/licenses/gpl-3.0.en.html)

---

*This project was entirely generated using [Claude](https://claude.ai) by Anthropic.*
