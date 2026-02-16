import Foundation

struct ReminderItem: Codable, Identifiable {
    let id: UUID
    var note: String
    var fireDate: Date
    var fired: Bool

    init(note: String, fireDate: Date) {
        self.id = UUID()
        self.note = note
        self.fireDate = fireDate
        self.fired = false
    }
}
