import Foundation

struct ReminderItem: Codable, Identifiable {
    let id: UUID
    var note: String
    var fireDate: Date
    var fired: Bool
    var archived: Bool

    init(note: String, fireDate: Date) {
        self.id = UUID()
        self.note = note
        self.fireDate = fireDate
        self.fired = false
        self.archived = false
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        note = try container.decode(String.self, forKey: .note)
        fireDate = try container.decode(Date.self, forKey: .fireDate)
        fired = try container.decode(Bool.self, forKey: .fired)
        archived = try container.decodeIfPresent(Bool.self, forKey: .archived) ?? false
    }
}
