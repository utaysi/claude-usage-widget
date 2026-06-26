import Foundation
import WebKit
import ClaudeUsageCore

/// Owns a persistent WKWebView signed into claude.ai and fetches usage by
/// running fetch() inside the page (so cookies + Cloudflare are handled by the browser).
@MainActor
final class UsageService: NSObject, WKNavigationDelegate {
    enum Result {
        case success(UsageSnapshot)
        case needsLogin
        case transient(String)
    }

    let webView: WKWebView
    private let store: SharedStore
    private var loadContinuations: [CheckedContinuation<Void, Never>] = []
    private var isLoaded = false

    init(store: SharedStore) {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default() // persistent cookies survive launches
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.store = store
        super.init()
        self.webView.navigationDelegate = self
    }

    /// Loads claude.ai so the page origin is available for same-origin fetch().
    func loadSite() {
        isLoaded = false
        webView.load(URLRequest(url: URL(string: ClaudeAPI.base + "/")!))
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
        resumeWaiters()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        resumeWaiters()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        resumeWaiters()
    }

    private func resumeWaiters() {
        let conts = loadContinuations
        loadContinuations.removeAll()
        conts.forEach { $0.resume() }
    }

    private func waitForLoad() async {
        if isLoaded { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            loadContinuations.append(c)
        }
    }

    // MARK: Fetching

    /// Fetches usage; resolves org first if unknown. Persists snapshot on success.
    func refresh() async -> Result {
        await waitForLoad()

        var org = store.orgId
        if org == nil {
            guard let r = await jsFetch(path: ClaudeAPI.orgsPath) else { return .transient("io") }
            switch UsageHTTP.classify(status: r.status, redirectedToLogin: r.toLogin, body: r.body) {
            case .needsLogin:
                store.authState = .needsLogin; return .needsLogin
            case .transient(let why):
                return .transient(why)
            case .success:
                guard let id = OrgSelector.selectOrgId(from: Data(r.body.utf8)) else {
                    return .transient("org-unknown")
                }
                org = id; store.orgId = id
            }
        }

        guard let r = await jsFetch(path: ClaudeAPI.usagePath(org: org!)) else { return .transient("io") }
        switch UsageHTTP.classify(status: r.status, redirectedToLogin: r.toLogin, body: r.body) {
        case .needsLogin:
            store.authState = .needsLogin; return .needsLogin
        case .transient(let why):
            return .transient(why)
        case .success:
            do {
                let snap = try UsageParser.parse(Data(r.body.utf8), now: Date())
                store.saveSnapshot(snap); store.authState = .ok
                return .success(snap)
            } catch {
                return .transient("parse")
            }
        }
    }

    /// Copies claude.ai cookies + the page User-Agent into the Keychain so the
    /// background task can replay an authenticated URLSession request.
    func harvestCredentials() async {
        let ua = (try? await webView.callAsyncJavaScript(
            "return navigator.userAgent;", arguments: [:], in: nil, contentWorld: .page)) as? String
        guard let ua, !ua.isEmpty else { return }

        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies: [HTTPCookie] = await withCheckedContinuation { cont in
            cookieStore.getAllCookies { cont.resume(returning: $0) }
        }
        let claude = cookies.filter { $0.domain.contains("claude.ai") }
        guard !claude.isEmpty else { return }
        let header = claude.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        Keychain.saveCredentials(Credentials(cookieHeader: header, userAgent: ua))
    }

    private struct JSResult { let status: Int; let toLogin: Bool; let body: String }

    private func jsFetch(path: String) async -> JSResult? {
        let js = """
        const res = await fetch(path, { credentials: 'include', headers: { 'Accept': '*/*' } });
        const body = await res.text();
        const toLogin = res.redirected && res.url.indexOf('/login') !== -1;
        return JSON.stringify({ status: res.status, toLogin: toLogin, body: body });
        """
        do {
            let value = try await webView.callAsyncJavaScript(
                js, arguments: ["path": path], in: nil, contentWorld: .page)
            guard let s = value as? String,
                  let obj = try? JSONSerialization.jsonObject(with: Data(s.utf8)) as? [String: Any],
                  let status = obj["status"] as? Int else { return nil }
            return JSResult(status: status,
                            toLogin: obj["toLogin"] as? Bool ?? false,
                            body: obj["body"] as? String ?? "")
        } catch {
            return nil
        }
    }

    /// Clears the claude.ai session (logout).
    func clearSession() async {
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let records = await dataStore.dataRecords(ofTypes: types)
        let claude = records.filter { $0.displayName.contains("claude") || $0.displayName.contains("anthropic") }
        await dataStore.removeData(ofTypes: types, for: claude)
        self.store.authState = .needsLogin
    }
}
