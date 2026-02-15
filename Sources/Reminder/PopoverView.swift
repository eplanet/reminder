import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var manager: ReminderManager

    @State private var input: String = ""
    @State private var parsed: ParsedReminder?
    @State private var showError: Bool = false
    @FocusState private var isInputFocused: Bool

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

            TextField("e.g. \"Buy groceries tomorrow at 9am\"", text: $input)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit { submit() }
                .onChange(of: input) { newValue in
                    parsed = DateParser.parse(newValue)
                    showError = false
                }

            if let parsed = parsed {
                HStack(spacing: 4) {
                    if !parsed.note.isEmpty {
                        Text("\"\(parsed.note)\"")
                            .fontWeight(.medium)
                        Text("—")
                    }
                    Text(dateFormatter.string(from: parsed.date))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            if showError {
                Text("Could not parse. Try \"Buy milk tomorrow at 9am\" or \"Call mom in 2h\".")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if !manager.pendingReminders.isEmpty {
                Divider()

                Text("Upcoming")
                    .font(.headline)

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(manager.pendingReminders) { item in
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
        .onAppear {
            isInputFocused = true
        }
    }

    private func submit() {
        guard let result = DateParser.parse(input) else {
            showError = true
            return
        }

        let note = result.note.isEmpty ? input : result.note
        manager.scheduleReminder(note: note, at: result.date)
        input = ""
        parsed = nil
    }
}
