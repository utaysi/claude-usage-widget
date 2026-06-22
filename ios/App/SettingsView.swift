import SwiftUI
import ClaudeUsageCore

struct SettingsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Form {
            Section("Status") {
                LabeledContent("Account", value: model.needsLogin ? "Logged out" : "Logged in")
                if let snap = model.snapshot {
                    LabeledContent("Last update") { Text(snap.fetchedAt, style: .relative) }
                }
                LabeledContent("Org id", value: model.store.orgId ?? "—")
            }
            Section("Appearance") {
                HStack(spacing: 14) {
                    ForEach(UsageTint.presets, id: \.self) { hex in
                        Circle()
                            .fill(Color(usageHex: hex) ?? .orange)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.primary,
                                lineWidth: model.accentColorHex.caseInsensitiveCompare(hex) == .orderedSame ? 2 : 0))
                            .onTapGesture { model.setAccent(hex) }
                            .accessibilityLabel(hex)
                    }
                }
                .padding(.vertical, 4)
                ColorPicker("Custom color", selection: Binding(
                    get: { Color(usageHex: model.accentColorHex) ?? .orange },
                    set: { model.setAccent($0.toHex() ?? UsageTint.defaultAccentHex) }))
                Text("Bars turn red at 90%+ regardless of this color.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Section("Account") {
                Button(role: .destructive) {
                    Task { await model.logout() }
                } label: {
                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            Section("About") {
                LabeledContent("App Group", value: AppConfig.appGroupID)
                LabeledContent("Data source", value: "claude.ai/api/.../usage")
            }
        }
        .navigationTitle("Settings")
    }
}
