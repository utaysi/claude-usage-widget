# Claude Usage Widget — iOS (token-based)

A native iOS home-screen and lock-screen widget showing **Claude** and **Codex**
(ChatGPT-plan) usage — the **5-hour** and **weekly** rolling windows — as a
utilization percentage plus a live countdown to each reset. iOS counterpart to
the Android app in this repo; built for personal sideloading (not the App Store).

> **This is an *alternative* auth approach** to the webview-login iOS PR. It uses
> the local CLI OAuth tokens instead of an in-app login. Please read the
> **Caveat** section — it's the maintainer's call which approach (if either) to take.

## How it works

There's no in-app login and no embedded web view. You paste the OAuth token your
CLI already stored locally, and the app calls each provider's usage API directly:

- **Claude** → `GET https://api.anthropic.com/api/oauth/usage`
  (`Authorization: Bearer <token>`, `anthropic-beta: oauth-2025-04-20`).
- **Codex** → `GET https://chatgpt.com/backend-api/wham/usage`
  (`Authorization: Bearer <token>`, `ChatGPT-Account-Id: <id>`).

Both return the primary (5h) and secondary (weekly) windows. The token is stored
in the device **Keychain** and **auto-refreshed** when it expires (Anthropic:
`console.anthropic.com/v1/oauth/token`; OpenAI: `auth.openai.com/oauth/token`),
so it's a one-time paste. Result is cached to a shared **App Group**; the
**WidgetKit extension** reads it. Background refresh works (plain `URLSession`,
no web view).

### Setup

In **Settings → Set Claude token / Set Codex token**, paste the output of:

```bash
cat ~/.claude/.credentials.json   # Claude (Claude Code login)
cat ~/.codex/auth.json            # Codex (codex login)
```

Each placed widget is configured individually (long-press → **Edit Widget**) to
show Claude, Codex, or both. Requires **iOS 17+**.

## Caveat (please read)

This approach **reuses the official CLIs' public OAuth client IDs** to call
endpoints intended for first-party clients. Anthropic has issued legal requests
over third-party reuse of its OAuth client (the `opencode` project removed its
Claude OAuth support as a result). Reading *usage* is more benign than providing
API access, but this is undocumented private API use that could change or be
restricted without notice. For that reason this is offered as a personal,
sideload-only option — the webview-login variant (which does **not** reuse those
OAuth clients) is the safer choice for a publicly distributed app. **Your call.**

Why this exists anyway: the Codex web usage API is sentinel/proof-of-work gated,
so a cookie/webview session can't read it at all — the CLI token is the only way
to show Codex usage. Claude *can* be read via webview login; it's included here
only so both providers share one clean code path.

## Project layout

```
Core/        Swift package — models, parsing, OAuth token/refresh, usage clients + unit tests
App/         SwiftUI host app (token paste, refresh, settings)
Widget/      WidgetKit extension (timeline provider + views)
Shared/      Code compiled into both targets (color tint helpers)
project.yml  XcodeGen spec (run `xcodegen generate` to (re)create the .xcodeproj)
```

## Build & run

Requires macOS + Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`). Minimum deployment target is iOS 17.

```bash
cd ios
swift test --package-path Core   # run the unit tests
xcodegen generate                # generate ClaudeUsage.xcodeproj
open ClaudeUsage.xcodeproj
```

Set your own bundle ids / App Group (the project ships with a `com.example`
placeholder): edit `project.yml`, both `*.entitlements`, and
`Core/Sources/ClaudeUsageCore/Constants.swift` (`appGroupID`, `bgRefreshTaskID`),
then re-run `xcodegen generate`. Set your signing **Team** on both targets and
enable the App Group capability on both.
