import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: ReminderManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            // Sound
            HStack {
                Text("Sound")
                    .frame(width: 60, alignment: .leading)

                Menu {
                    Button("Silent") { manager.selectSilent() }
                    Divider()
                    ForEach(systemSounds, id: \.self) { name in
                        Button(name) { manager.selectSystemSound(name) }
                    }
                    Divider()
                    Button("Custom file\u{2026}") { manager.selectCustomSound() }
                } label: {
                    Text(manager.soundDisplayName)
                        .frame(width: 100, alignment: .leading)
                }
                .frame(width: 120)

                Button {
                    manager.previewSound()
                } label: {
                    Image(systemName: manager.isSilent ? "speaker.slash" : "speaker.wave.2")
                }
                .buttonStyle(.borderless)
                .help("Preview sound")
                .disabled(manager.isSilent)
            }

            Divider()

            // Archive preference
            Toggle("Archive deleted reminders", isOn: $manager.archiveOnDelete)
                .font(.subheadline)

            Text("When enabled, deleted reminders are kept in the JSON file but hidden from the app.")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            // Auto-mark expired as fired
            Toggle("Auto-mark expired reminders as fired", isOn: $manager.autoMarkExpiredAsFired)
                .font(.subheadline)

            Text("When enabled, overdue reminders are silently marked as fired without notification on app restart or wake.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300)
    }
}
