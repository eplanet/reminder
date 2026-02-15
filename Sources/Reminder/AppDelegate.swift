import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var manager: ReminderManager?
    private let alertController = AlertWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start scheduling timers once the app is fully launched
        DispatchQueue.main.async {
            self.manager?.start()
            self.observeFiredReminders()
        }
    }

    private func observeFiredReminders() {
        guard let manager = manager else { return }

        // Poll for fired reminders using a display link / timer
        // This bridges the @Published property to AppKit
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self, weak manager] _ in
            guard let self = self, let manager = manager else { return }
            Task { @MainActor in
                if let item = manager.firedReminder {
                    self.alertController.show(item: item) {
                        manager.dismissFiredReminder()
                    }
                }
            }
        }
    }
}
