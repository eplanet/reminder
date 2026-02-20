import AppKit
import AVFoundation
import Foundation

let systemSounds = [
    "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
    "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"
]

private let customSoundMarker = "__custom__"
private let silentMarker = "__silent__"

@MainActor
class ReminderManager: ObservableObject {
    /// Display name shown in the picker. System sound name or "Custom".
    @Published var selectedSoundName: String {
        didSet {
            UserDefaults.standard.set(selectedSoundName, forKey: soundKey)
        }
    }

    /// Path to the custom MP3 file, if any.
    @Published var customSoundPath: String? {
        didSet {
            UserDefaults.standard.set(customSoundPath, forKey: customSoundKey)
        }
    }

    /// All reminders (pending + fired), persisted to disk.
    private var allReminders: [ReminderItem] = []

    @Published var pendingReminders: [ReminderItem] = []
    @Published var firedReminders: [ReminderItem] = []

    @Published var archiveOnDelete: Bool {
        didSet {
            UserDefaults.standard.set(archiveOnDelete, forKey: archiveKey)
        }
    }

    @Published var autoMarkExpiredAsFired: Bool {
        didSet {
            UserDefaults.standard.set(autoMarkExpiredAsFired, forKey: autoMarkExpiredKey)
        }
    }

    private let soundKey = "reminder_sound"
    private let customSoundKey = "reminder_custom_sound_path"
    private let archiveKey = "reminder_archive_on_delete"
    private let autoMarkExpiredKey = "reminder_auto_mark_expired"
    private var dispatchers: [UUID: DispatchSourceTimer] = [:]
    private var audioPlayer: AVAudioPlayer?

    var isSilent: Bool { selectedSoundName == silentMarker }
    var isCustomSound: Bool { selectedSoundName == customSoundMarker }

    var soundDisplayName: String {
        if isSilent { return "Silent" }
        if isCustomSound { return customSoundPath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "Custom" }
        return selectedSoundName
    }

    var customSoundDisplayName: String? {
        guard let path = customSoundPath else { return nil }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    private static var storageDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/reminder", isDirectory: true)
    }

    private static var storageFile: URL {
        storageDir.appendingPathComponent("reminders.json")
    }

    func selectSilent() {
        selectedSoundName = silentMarker
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: soundKey) ?? "Glass"
        self.selectedSoundName = saved
        self.customSoundPath = UserDefaults.standard.string(forKey: customSoundKey)
        self.archiveOnDelete = UserDefaults.standard.object(forKey: archiveKey) as? Bool ?? true
        self.autoMarkExpiredAsFired = UserDefaults.standard.object(forKey: autoMarkExpiredKey) as? Bool ?? false
        loadReminders()
        refreshLists()
        rescheduleAll()

        // Check for overdue reminders on system wake and screen unlock
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.checkOverdueReminders() }
        }
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.checkOverdueReminders() }
        }
    }

    /// Check for and fire any overdue reminders (called on wake/unlock).
    private func checkOverdueReminders() {
        let now = Date()
        let overdue = allReminders.filter { !$0.fired && !$0.archived && $0.fireDate <= now }
        for item in overdue {
            dispatchers[item.id]?.cancel()
            dispatchers.removeValue(forKey: item.id)
            if autoMarkExpiredAsFired {
                if let index = allReminders.firstIndex(where: { $0.id == item.id }) {
                    allReminders[index].fired = true
                }
            } else {
                fireReminder(item)
            }
        }
        if !overdue.isEmpty && autoMarkExpiredAsFired {
            save()
            refreshLists()
        }
    }

    func selectSystemSound(_ name: String) {
        selectedSoundName = name
    }

    func selectCustomSound() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.mp3, .audio]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a custom sound file"

        if panel.runModal() == .OK, let url = panel.url {
            customSoundPath = url.path
            selectedSoundName = customSoundMarker
        }
    }

    func scheduleReminder(note: String, at fireDate: Date) {
        let item = ReminderItem(note: note, fireDate: fireDate)

        scheduleDispatch(for: item)

        allReminders.append(item)
        allReminders.sort { $0.fireDate < $1.fireDate }
        save()
        refreshLists()
    }

    func updateReminder(_ item: ReminderItem, note: String, fireDate: Date) {
        // Cancel old timer
        dispatchers[item.id]?.cancel()
        dispatchers.removeValue(forKey: item.id)

        // Update in place
        if let index = allReminders.firstIndex(where: { $0.id == item.id }) {
            allReminders[index].note = note
            allReminders[index].fireDate = fireDate
            allReminders[index].fired = false
            scheduleDispatch(for: allReminders[index])
        }
        allReminders.sort { $0.fireDate < $1.fireDate }
        save()
        refreshLists()
    }

    func removeReminder(_ item: ReminderItem) {
        dispatchers[item.id]?.cancel()
        dispatchers.removeValue(forKey: item.id)
        if archiveOnDelete {
            if let index = allReminders.firstIndex(where: { $0.id == item.id }) {
                allReminders[index].archived = true
            }
        } else {
            allReminders.removeAll { $0.id == item.id }
        }
        save()
        refreshLists()
    }

    func previewSound() {
        playSound()
    }

    // MARK: - Sound playback

    private func playSound() {
        if isSilent { return }
        if isCustomSound, let path = customSoundPath {
            let url = URL(fileURLWithPath: path)
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } else {
            NSSound(named: NSSound.Name(selectedSoundName))?.play()
        }
    }

    // MARK: - Notifications

    private func sendNotification(for item: ReminderItem) {
        let escapedBody = item.note.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        // osascript sound name only works with system sounds; for custom/silent we play separately
        let soundClause: String
        if isCustomSound || isSilent {
            soundClause = ""
        } else {
            soundClause = " sound name \"\(selectedSoundName)\""
        }

        let script = "display notification \"\(escapedBody)\" with title \"Reminder\"\(soundClause)"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    // MARK: - Dispatch-based scheduling

    private func scheduleDispatch(for item: ReminderItem) {
        let interval = item.fireDate.timeIntervalSinceNow
        if interval <= 0 {
            if autoMarkExpiredAsFired {
                // Silently mark as fired without notification
                if let index = allReminders.firstIndex(where: { $0.id == item.id }) {
                    allReminders[index].fired = true
                }
                save()
                refreshLists()
            } else {
                fireReminder(item)
            }
            return
        }

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

        if let index = allReminders.firstIndex(where: { $0.id == item.id }) {
            allReminders[index].fired = true
        }
        save()
        refreshLists()

        playSound()
        sendNotification(for: item)
    }

    private func rescheduleAll() {
        for item in allReminders where !item.fired {
            scheduleDispatch(for: item)
        }
    }

    private func refreshLists() {
        pendingReminders = allReminders.filter { !$0.fired && !$0.archived }.sorted { $0.fireDate < $1.fireDate }
        firedReminders = allReminders.filter { $0.fired && !$0.archived }.sorted { $0.fireDate > $1.fireDate }
    }

    // MARK: - Persistence

    private func save() {
        do {
            try FileManager.default.createDirectory(at: Self.storageDir, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(allReminders)
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
        allReminders = items.sorted { $0.fireDate < $1.fireDate }
    }
}
