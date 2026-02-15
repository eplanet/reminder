import SwiftUI

@main
struct ReminderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager = ReminderManager()

    var body: some Scene {
        MenuBarExtra("Reminder", systemImage: "bell.badge") {
            PopoverView()
                .environmentObject(manager)
                .onAppear {
                    appDelegate.manager = manager
                }
        }
        .menuBarExtraStyle(.window)
    }
}
