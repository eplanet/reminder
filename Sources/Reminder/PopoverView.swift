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

            if !manager.pendingReminders.isEmpty || !manager.firedReminders.isEmpty {
                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if !manager.pendingReminders.isEmpty {
                            Text("Upcoming")
                                .font(.headline)

                            ForEach(manager.pendingReminders) { item in
                                ReminderRow(item: item, isFired: false, dateFormatter: dateFormatter) {
                                    manager.removeReminder(item)
                                }
                            }
                        }

                        if !manager.firedReminders.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Past")
                                    .font(.headline)

                                ForEach(manager.firedReminders) { item in
                                    ReminderRow(item: item, isFired: true, dateFormatter: dateFormatter) {
                                        manager.removeReminder(item)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(8)
                            .padding(.top, manager.pendingReminders.isEmpty ? 0 : 4)
                        }
                    }
                }
                .frame(maxHeight: 250)
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

// MARK: - Reminder Row

private struct ReminderRow: View {
    let item: ReminderItem
    let isFired: Bool
    let dateFormatter: DateFormatter
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                LinkedText(text: item.note)
                    .font(.body)
                    .italic(isFired)
                    .foregroundColor(isFired ? .secondary : .primary)
                    .lineLimit(2)
                Text(dateFormatter.string(from: item.fireDate))
                    .font(.caption)
                    .italic(isFired)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.note, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Copy text")

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Linked Text

/// Renders text with URLs as clickable links.
private struct LinkedText: View {
    let text: String

    var body: some View {
        if let attributed = makeAttributedString() {
            Text(attributed)
        } else {
            Text(text)
        }
    }

    private func makeAttributedString() -> AttributedString? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let nsRange = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, range: nsRange)
        guard !matches.isEmpty else { return nil }

        var attributed = AttributedString(text)

        for match in matches {
            guard let range = Range(match.range, in: text),
                  let attrRange = Range(range, in: attributed),
                  let url = match.url else { continue }
            attributed[attrRange].link = url
            attributed[attrRange].underlineStyle = .single
        }

        return attributed
    }
}
