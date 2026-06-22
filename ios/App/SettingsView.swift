import SwiftUI
import ClaudeUsageCore

struct SettingsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Form {
            ForEach(model.providers) { p in
                let spec = ProviderSpec.spec(for: p)
                Section(spec.displayName) {
                    LabeledContent("Token", value: (model.needsLogin[p] ?? false) ? "Not set" : "Set")
                    if let snap = model.snapshots[p] {
                        LabeledContent("Last update") { Text(snap.fetchedAt, style: .relative) }
                    }
                    accentRow(for: p, label: "\(spec.displayName) color")
                    Button(role: .destructive) { model.logout(p) } label: {
                        Label("Clear \(spec.displayName) token", systemImage: "key.slash")
                    }
                }
            }
            Section("About") {
                LabeledContent("App Group", value: AppConfig.appGroupID)
                Text("Bars turn red at 90%+ regardless of the chosen color.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }

    @ViewBuilder private func accentRow(for p: Provider, label: String) -> some View {
        let current = model.accents[p] ?? UsageTint.defaultAccentHex
        HStack(spacing: 14) {
            ForEach(UsageTint.presets, id: \.self) { hex in
                Circle().fill(Color(usageHex: hex) ?? .orange).frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color.primary,
                        lineWidth: current.caseInsensitiveCompare(hex) == .orderedSame ? 2 : 0))
                    .onTapGesture { model.setAccent(hex, for: p) }
            }
        }
        .padding(.vertical, 4)
        ColorPicker(label, selection: Binding(
            get: { Color(usageHex: current) ?? .orange },
            set: { model.setAccent($0.toHex() ?? UsageTint.defaultAccentHex, for: p) }))
    }
}
