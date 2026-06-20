package com.usage.claudewidget.data

import android.annotation.SuppressLint
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume

/**
 * Silently re-mints a fresh cf_clearance cookie by loading claude.ai in an off-screen
 * WebView, which executes Cloudflare's JS challenge. Requires a still-valid sessionKey
 * cookie to already be present in the WebView jar (no user interaction needed).
 *
 * Must touch the WebView only on the main thread; safe to call from a background coroutine.
 */
object CloudflareResolver {

    /** @return true if a cf_clearance cookie was obtained and harvested into [storage]. */
    suspend fun resolve(context: Context, storage: Storage, timeoutMs: Long = 30_000): Boolean {
        // Ensure the WebView jar carries our session before loading the page.
        seedSessionCookie(storage)

        val ok = withTimeoutOrNull(timeoutMs) {
            runWebViewChallenge(context.applicationContext, storage)
        } ?: false

        return ok && !storage.cfClearance.isNullOrBlank()
    }

    private fun seedSessionCookie(storage: Storage) {
        val session = storage.sessionKey ?: return
        val cm = CookieManager.getInstance()
        cm.setAcceptCookie(true)
        cm.setCookie(Const.BASE, "${Const.COOKIE_SESSION}=$session; Domain=.claude.ai; Path=/")
    }

    @SuppressLint("SetJavaScriptEnabled")
    private suspend fun runWebViewChallenge(appCtx: Context, storage: Storage): Boolean =
        suspendCancellableCoroutine { cont ->
            val main = Handler(Looper.getMainLooper())
            main.post {
                lateinit var webView: WebView
                var settled = false
                val cm = CookieManager.getInstance()

                fun finish(result: Boolean, view: WebView) {
                    if (settled) return
                    settled = true
                    cm.flush()
                    if (result) CookieHarvester.harvest(storage)
                    view.stopLoading()
                    view.destroy()
                    if (cont.isActive) cont.resume(result)
                }

                webView = WebView(appCtx).apply {
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = true
                    storage.userAgent?.let { settings.userAgentString = it }
                    cm.setAcceptCookie(true)
                    cm.setAcceptThirdPartyCookies(this, true)

                    webViewClient = object : WebViewClient() {
                        override fun onPageFinished(view: WebView, url: String) {
                            // Cloudflare may reload several times; check whether clearance landed.
                            val cookies = cm.getCookie(Const.BASE) ?: ""
                            if (cookies.contains("${Const.COOKIE_CF}=")) {
                                finish(true, view)
                            }
                            // else: keep waiting; challenge page will navigate again, or we time out.
                        }
                    }
                }
                webView.loadUrl(Const.CHALLENGE_URL)

                cont.invokeOnCancellation {
                    main.post { if (!settled) { settled = true; webView.destroy() } }
                }
            }
        }
}
