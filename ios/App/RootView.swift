import SwiftUI
import ClaudeUsageCore

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let snap = model.snapshot {
                    WindowRow(title: "5H", window: snap.fiveHour)
                    WindowRow(title: "1W", window: snap.sevenDay)
                    Text("Updated \(snap.fetchedAt, style: .relative) ago")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "gauge.medium").font(.largeTitle)
                        Text("No data yet").font(.headline)
                        Text("Log in and refresh.").font(.subheadline).foregroundStyle(.secondary)
                    }
                }

                if let err = model.lastError {
                    Text("Last issue: \(err)").font(.caption2).foregroundStyle(.orange)
                }

                Button {
                    Task { await model.refresh() }
                } label: {
                    Label(model.isRefreshing ? "Refreshing…" : "Refresh now", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isRefreshing)

                Button {
                    showLogin = true
                } label: {
                    Label(model.needsLogin ? "Log in to Claude" : "Re-login to Claude", systemImage: "person.crop.circle")
                }
                .font(.callout)
            }
            .padding()
            .navigationTitle("Claude Usage")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink { SettingsView() } label: { Image(systemName: "gear") }
                }
            }
            .onChange(of: model.needsLogin) { needs in
                if needs { showLogin = true }
            }
            .sheet(isPresented: $showLogin) {
                LoginSheet(webView: model.service.webView) {
                    showLogin = false
                    Task { await model.refresh() }
                }
            }
            .task {
                await model.refresh()
                if model.snapshot == nil { showLogin = true }
            }
        }
    }
}

struct WindowRow: View {
    @EnvironmentObject var model: AppModel
    let title: String
    let window: UsageWindow

    private var color: Color { UsageTint.resolve(utilization: window.utilization, hex: model.accentColorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text(UsageFormat.percent(window.utilization)).font(.headline).foregroundStyle(color)
            }
            ProgressView(value: min(window.utilization, 100), total: 100)
                .tint(color)
            Text("resets \(window.resetsAt, style: .relative)")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
