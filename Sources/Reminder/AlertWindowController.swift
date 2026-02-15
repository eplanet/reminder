import AppKit
import SwiftUI

class AlertWindowController {
    private var window: NSWindow?

    func show(item: ReminderItem, onDismiss: @escaping () -> Void) {
        let contentView = AlertView(note: item.note, fireDate: item.fireDate) {
            onDismiss()
            self.close()
        }

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 380, height: 200)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Reminder"
        window.contentView = hostingView
        window.center()
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        // Force the app to the front
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func close() {
        window?.close()
        window = nil
    }
}

private struct AlertView: View {
    let note: String
    let fireDate: Date
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.fill")
                .font(.system(size: 36))
                .foregroundColor(.accentColor)

            Text(note)
                .font(.title3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Dismiss") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(24)
        .frame(minWidth: 300)
    }
}
