import AppKit
import Foundation

enum ReminderSound: String, CaseIterable, Codable {
    case basso = "Basso"
    case blow = "Blow"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case glass = "Glass"
    case hero = "Hero"
    case morse = "Morse"
    case ping = "Ping"
    case pop = "Pop"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case submarine = "Submarine"
    case tink = "Tink"

    func play() {
        NSSound(named: NSSound.Name(rawValue))?.play()
    }
}

@MainActor
class ReminderManager: ObservableObject {
    @Published var reminders: [ReminderItem] = []
    @Published var firedReminder: ReminderItem?
    @Published var selectedSound: ReminderSound {
        didSet { UserDefaults.standard.set(selectedSound.rawValue, forKey: soundKey) }
    }

    private let soundKey = "reminder_sound"
    private var dispatchers: [UUID: DispatchSourceTimer] = [:]

    private static var storageDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/reminder", isDirectory: true)
    }

    private static var storageFile: URL {
        storageDir.appendingPathComponent("reminders.json")
    }

    init() {
        let savedSound = UserDefaults.standard.string(forKey: soundKey)
        self.selectedSound = savedSound.flatMap { ReminderSound(rawValue: $0) } ?? .glass
        loadReminders()
        pruneExpiredReminders()
    }

    func start() {
        rescheduleAll()
    }

    func scheduleReminder(note: String, at fireDate: Date) {
        let item = ReminderItem(note: note, fireDate: fireDate)

        let interval = fireDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        scheduleDispatch(for: item)

        reminders.append(item)
        reminders.sort { $0.fireDate < $1.fireDate }
        saveReminders()
    }

    func removeReminder(_ item: ReminderItem) {
        dispatchers[item.id]?.cancel()
        dispatchers.removeValue(forKey: item.id)
        reminders.removeAll { $0.id == item.id }
        saveReminders()
    }

    func dismissFiredReminder() {
        firedReminder = nil
    }

    func previewSound() {
        selectedSound.play()
    }

    // MARK: - Dispatch-based scheduling

    private func scheduleDispatch(for item: ReminderItem) {
        let interval = item.fireDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + interval)
        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.fireReminder(item)
            }
        }
        dispatchers[item.id] = timer
        timer.resume()
    }

    private func fireReminder(_ item: ReminderItem) {
        dispatchers[item.id]?.cancel()
        dispatchers.removeValue(forKey: item.id)
        reminders.removeAll { $0.id == item.id }
        saveReminders()

        // Play the selected sound
        selectedSound.play()

        // Set the fired reminder so the alert window appears
        firedReminder = item

        // Also send an osascript notification as a banner
        let escapedBody = item.note.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "display notification \"\(escapedBody)\" with title \"Reminder\" sound name \"\(selectedSound.rawValue)\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    private func rescheduleAll() {
        for item in reminders {
            scheduleDispatch(for: item)
        }
    }

    // MARK: - Persistence

    private func saveReminders() {
        do {
            try FileManager.default.createDirectory(at: Self.storageDir, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(reminders)
            try data.write(to: Self.storageFile, options: .atomic)
        } catch {
            print("Failed to save reminders: \(error)")
        }
    }

    private func loadReminders() {
        guard let data = try? Data(contentsOf: Self.storageFile) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let items = try? decoder.decode([ReminderItem].self, from: data) else { return }
        reminders = items.sorted { $0.fireDate < $1.fireDate }
    }

    private func pruneExpiredReminders() {
        let now = Date()
        reminders.removeAll { $0.fireDate < now }
        saveReminders()
    }
}
