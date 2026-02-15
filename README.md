# Reminder

A lightweight macOS menu bar app for quickly creating reminders with natural language time input.

## Features

- **Menu bar app** — lives in your system tray as a bell icon, no dock clutter
- **Natural language time input** — type times like `in 2h`, `tomorrow at 9am`, `next Monday at 10am`, `in 30m`
- **Live date preview** — see the resolved date as you type
- **Popup alert** — a floating window pops up in front of all other windows when a reminder fires
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

## Usage

1. Click the bell icon in the menu bar
2. Type your reminder note in the first field
3. Type when you want to be reminded in the second field (e.g. `in 10m`, `tomorrow at 9am`)
4. Press **Enter** or click **Remind Me**
5. When the time comes, a floating alert window appears with a sound

## Time Input Examples

| Input | Meaning |
|---|---|
| `in 5m` | 5 minutes from now |
| `in 2h` | 2 hours from now |
| `in 1d` | 1 day from now |
| `in 1w` | 1 week from now |
| `tomorrow at 9am` | Tomorrow at 9:00 AM |
| `next Monday at 10am` | Next Monday at 10:00 AM |
| `Friday at 3pm` | This Friday at 3:00 PM |

## License

[GPL v3](https://www.gnu.org/licenses/gpl-3.0.en.html)

---

*This project was entirely generated using [Claude](https://claude.ai) by Anthropic.*
