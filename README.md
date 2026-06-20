<div align="center">

# 🦞 Claude Usage Widget

**An Android home-screen widget for your Claude subscription usage.**
Keeps your `5H` and `1W` percentages (plus *“resets in”* countdowns) live on your home screen.

![status: working](https://img.shields.io/badge/status-working-brightgreen)
![platform: Android 8+](https://img.shields.io/badge/platform-Android%208%2B-3DDC84?logo=android&logoColor=white)
![built with: Kotlin + Glance](https://img.shields.io/badge/built%20with-Kotlin%20%2B%20Glance-7F52FF?logo=kotlin&logoColor=white)

<br />

<table>
  <tr>
    <td align="center" valign="middle"><img src="docs/widget-focus.png" alt="Claude Usage widget close-up" width="380" /></td>
    <td align="center" valign="middle"><img src="docs/home-screen.png" alt="The widget on an Android home screen" width="210" /></td>
  </tr>
</table>

</div>

<br />

You sign in once on the phone, and the widget refreshes itself in the background. No need to open the app again.

---

## ✨ Highlights

- **Two rolling windows at a glance.** The 5-hour and 1-week usage percentages, with a live countdown to each reset.
- **Refreshes itself.** A background job updates every ~15 minutes; tap the widget to force an immediate refresh.
- **Sign in once.** A single `claude.ai` login; you only re-authenticate when the long-lived session finally expires (weeks).
- **Resizes freely.** Snaps between a compact and a full layout, and adapts to light & dark themes.

---

## ⚠️ Unofficial: read this first

Anthropic does **not** provide a public API for subscription (Pro/Max) usage. The official Rate Limits API only exposes *configured* org limits for API/Console accounts, not your consumption against the 5-hour and weekly windows. This widget works by replaying the same **undocumented internal endpoint** that `claude.ai/settings/usage` calls in the browser (`GET /api/organizations/{org}/usage`), authorized by session cookies harvested from an in-app WebView login.

That means it can break at any time if Anthropic changes the endpoint, the auth flow, or the Cloudflare protection in front of it. It is not a sanctioned integration, so use it for your own account only, and don't expect it to be stable forever.

---

## 🛠 How it works

You log in once through a real `claude.ai` WebView (magic-link or Google). The app harvests the `sessionKey` and `cf_clearance` cookies plus the exact WebView User-Agent, stores them encrypted on-device, and then fetches usage headlessly with `OkHttp`. Because `cf_clearance` is short-lived and Cloudflare-gated, when a headless fetch hits Cloudflare's challenge the app silently re-solves it by loading `claude.ai` in an off-screen WebView (no interaction needed while `sessionKey` is still valid) and retries. A `WorkManager` job refreshes every ~15 minutes, and tapping the widget forces an immediate refresh. You only sign in again when the long-lived `sessionKey` itself finally expires, at which point the widget shows a *“Tap to sign in”* state.

The widget uses two reusable Glance layouts and snaps to whichever fits: a **Compact** layout (mascot + two mini bars + percentages, for roughly 1×1) and a **Full** layout (mascot + label + two bars with percentage and *“resets in”* for each). Both adapt to light and dark themes, and a small amber dot appears when the displayed numbers are stale.

---

## 📋 Requirements

- A Claude **Pro/Max** subscription (this reads consumer subscription usage, not API-key usage).
- **Android 8.0 (API 26)** or newer. Built and tested on a Pixel 9 / Android 16.
- For building: **JDK 17**, the Android SDK with platform 36, and the bundled Gradle wrapper.

---

## 🚀 Build and deploy to your phone

**1. Point Gradle at your Android SDK** by creating `local.properties` in the project root (gitignored):

```properties
sdk.dir=/path/to/your/Android/Sdk
```

**2. Build the debug APK** with the Gradle wrapper:

```bash
./gradlew :app:assembleDebug
```

**3. Install it.** The APK lands at `app/build/outputs/apk/debug/app-debug.apk`. Enable USB debugging (Settings → System → Developer options → USB debugging), plug in the phone, and run:

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

> Alternatively, copy that APK to the phone and tap it to sideload it directly.

---

## 👋 First-run setup

1. Open the **Claude Usage** app and tap **Sign in**, then complete the normal `claude.ai` login in the WebView. It closes automatically once it captures your session.
2. Tap **Test fetch now** to confirm it prints your current `5H` and `1W` percentages. These should match `claude.ai/settings/usage`.
3. Tap **Disable battery optimization** and allow it, so Android doesn't kill the 15-minute background refresh.
4. Long-press your home screen → **Widgets** → **Claude Usage**, drag it on, and resize it however you like. Tap it any time to refresh.

---

## 🗂 Project layout

| Path | What lives there |
| --- | --- |
| `app/.../data` | Endpoint constants, encrypted storage, cookie harvesting, the Cloudflare resolver, and the repository that orchestrates fetch, Cloudflare retry, and auth-state transitions. |
| `auth/LoginActivity.kt` | The WebView login. |
| `ui/MainActivity.kt` | The setup / debug screen. |
| `widget/` | The Glance widget and its layouts. |
| `work/` | Background refresh scheduling. |

---

## 🔒 Security notes

Credentials (`sessionKey`, `cf_clearance`, User-Agent, org ID) are stored in `EncryptedSharedPreferences` backed by the Android Keystore, and `android:allowBackup="false"` keeps them out of cloud backups. The `sessionKey` is as sensitive as your account password (anyone who extracts it can act as you), so treat a rooted or compromised device accordingly. No secrets are stored in the repo or baked into the APK.

---

## 🧭 Next steps

- **Release signing.** For a more permanent install, configure a release signing config and build a minified release APK instead of the debug build.
