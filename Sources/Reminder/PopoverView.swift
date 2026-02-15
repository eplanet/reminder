import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var manager: ReminderManager

    @State private var note: String = ""
    @State private var timeInput: String = ""
    @State private var parsedDate: Date?
    @State private var showError: Bool = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Reminder")
                .font(.headline)

            TextField("What do you want to be reminded about?", text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)

            TextField("When? e.g. \"in 2h\", \"tomorrow at 9am\"", text: $timeInput)
                .textFieldStyle(.roundedBorder)
                .onSubmit { submit() }
                .onChange(of: timeInput) { newValue in
                    parsedDate = DateParser.parse(newValue)
                    showError = false
                }

            if let date = parsedDate {
                Text("Will remind: \(dateFormatter.string(from: date))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if showError {
                Text("Could not parse the time. Try \"in 2h\" or \"tomorrow at 9am\".")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                Spacer()
                Button("Remind Me") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(note.trimmingCharacters(in: .whitespaces).isEmpty || timeInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }

            if !manager.reminders.isEmpty {
                Divider()

                Text("Upcoming")
                    .font(.headline)

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(manager.reminders) { item in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.note)
                                        .font(.body)
                                        .lineLimit(2)
                                    Text(dateFormatter.string(from: item.fireDate))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    manager.removeReminder(item)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }

            Divider()

            HStack {
                Text("Sound")
                    .font(.subheadline)
                Picker("", selection: $manager.selectedSound) {
                    ForEach(ReminderSound.allCases, id: \.self) { sound in
                        Text(sound.rawValue).tag(sound)
                    }
                }
                .labelsHidden()
                .frame(width: 120)

                Button {
                    manager.previewSound()
                } label: {
                    Image(systemName: "speaker.wave.2")
                }
                .buttonStyle(.borderless)
                .help("Preview sound")

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 320)
    }

    private func submit() {
        guard let date = DateParser.parse(timeInput) else {
            showError = true
            return
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        guard !trimmedNote.isEmpty else { return }

        manager.scheduleReminder(note: trimmedNote, at: date)
        note = ""
        timeInput = ""
        parsedDate = nil
    }
}
