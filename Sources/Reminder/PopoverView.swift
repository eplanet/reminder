import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var manager: ReminderManager

    @State private var input: String = ""
    @State private var parsed: ParsedReminder?
    @State private var showError: Bool = false
    @State private var editingItem: ReminderItem?
    @State private var showSettings: Bool = false
    @FocusState private var isInputFocused: Bool

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private var isEditing: Bool { editingItem != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "Edit Reminder" : "New Reminder")
                .font(.headline)

            TextEditor(text: $input)
                .font(.body)
                .frame(height: 54)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .focused($isInputFocused)
                .onChange(of: input) { newValue in
                    // Submit on Enter (but allow Shift+Enter for newlines)
                    if newValue.hasSuffix("\n") {
                        input = String(newValue.dropLast())
                        submit()
                        return
                    }
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

            if isEditing {
                HStack {
                    Spacer()
                    Button("Cancel") { cancelEdit() }
                        .keyboardShortcut(.escape, modifiers: [])
                }
            }

            if !manager.pendingReminders.isEmpty || !manager.firedReminders.isEmpty {
                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if !manager.pendingReminders.isEmpty {
                            Text("Upcoming")
                                .font(.headline)

                            ForEach(manager.pendingReminders) { item in
                                ReminderRow(
                                    item: item,
                                    isFired: false,
                                    isEditing: editingItem?.id == item.id,
                                    dateFormatter: dateFormatter,
                                    onEdit: { startEdit(item) },
                                    onDelete: { manager.removeReminder(item) }
                                )
                            }
                        }

                        if !manager.firedReminders.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Past")
                                    .font(.headline)

                                ForEach(manager.firedReminders) { item in
                                    ReminderRow(
                                        item: item,
                                        isFired: true,
                                        isEditing: false,
                                        dateFormatter: dateFormatter,
                                        onEdit: nil,
                                        onDelete: { manager.removeReminder(item) }
                                    )
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
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .help("Settings")
                .popover(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(manager)
                }

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

        if let item = editingItem {
            manager.updateReminder(item, note: note, fireDate: result.date)
            editingItem = nil
        } else {
            manager.scheduleReminder(note: note, at: result.date)
        }

        input = ""
        parsed = nil
    }

    private func startEdit(_ item: ReminderItem) {
        editingItem = item
        input = item.note + " " + dateFormatter.string(from: item.fireDate)
        isInputFocused = true
    }

    private func cancelEdit() {
        editingItem = nil
        input = ""
        parsed = nil
    }
}

// MARK: - Reminder Row

private struct ReminderRow: View {
    let item: ReminderItem
    let isFired: Bool
    let isEditing: Bool
    let dateFormatter: DateFormatter
    let onEdit: (() -> Void)?
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

            if let onEdit = onEdit {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(isEditing ? .accentColor : .secondary)
                }
                .buttonStyle(.borderless)
                .help("Edit reminder")
            }

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
        .background(isEditing ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
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
