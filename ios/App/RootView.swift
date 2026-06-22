import SwiftUI
import ClaudeUsageCore

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var tokenSheet: Provider?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    ForEach(model.providers) { providerCard($0) }
                    Button { Task { await model.refreshAll() } } label: {
                        Label(model.isRefreshing ? "Refreshing…" : "Refresh now", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isRefreshing)
                }
                .padding()
            }
            .navigationTitle("Usage")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink { SettingsView() } label: { Image(systemName: "gear") }
                }
            }
            .sheet(item: $tokenSheet) { p in
                TokenSheet(spec: ProviderSpec.spec(for: p),
                           save: { text in await model.setToken(p, fromPasted: text) },
                           onDone: { tokenSheet = nil })
            }
            .task { await model.refreshAll() }
        }
    }

    @ViewBuilder private func providerCard(_ p: Provider) -> some View {
        let spec = ProviderSpec.spec(for: p)
        VStack(alignment: .leading, spacing: 10) {
            Text(spec.displayName).font(.headline)
            if let snap = model.snapshots[p] {
                WindowRow(title: "5H", window: snap.fiveHour, provider: p)
                WindowRow(title: "1W", window: snap.sevenDay, provider: p)
                Text("Updated \(snap.fetchedAt, style: .relative) ago")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("No data — set your token below.").font(.subheadline).foregroundStyle(.secondary)
            }
            if let err = model.lastError[p] {
                Text(err).font(.caption2).foregroundStyle(.orange).textSelection(.enabled)
            }
            Button { tokenSheet = p } label: {
                Label((model.needsLogin[p] ?? false) ? "Set \(spec.displayName) token" : "Update \(spec.displayName) token",
                      systemImage: "key")
            }
            .font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct WindowRow: View {
    @EnvironmentObject var model: AppModel
    let title: String
    let window: UsageWindow
    let provider: Provider

    private var color: Color {
        UsageTint.resolve(utilization: window.utilization, hex: model.accents[provider])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text(UsageFormat.percent(window.utilization)).font(.headline).foregroundStyle(color)
            }
            ProgressView(value: min(window.utilization, 100), total: 100).tint(color)
            Text("resets \(window.resetsAt, style: .relative)").font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// Paste a provider's CLI credential to authenticate (the only working path).
struct TokenSheet: View {
    let spec: ProviderSpec
    let save: (String) async -> Bool
    let onDone: () -> Void
    @State private var text = ""
    @State private var status: String?
    @State private var working = false

    private var empty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(spec.tokenHint).font(.footnote).foregroundStyle(.secondary)
                Text("Stored only in this device's Keychain and refreshed automatically.")
                    .font(.caption2).foregroundStyle(.secondary)
                TextEditor(text: $text)
                    .font(.system(.caption, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                if let status { Text(status).font(.caption).foregroundStyle(.orange) }
            }
            .padding()
            .navigationTitle("\(spec.displayName) token")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onDone) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            working = true; status = nil
                            let ok = await save(text)
                            working = false
                            if ok { onDone() }
                            else { status = "Couldn't read a token from that. Paste the whole file contents (or the access token)." }
                        }
                    }
                    .disabled(empty || working)
                }
            }
        }
    }
}
