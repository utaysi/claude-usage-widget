package com.usage.claudewidget.data

object Const {
    const val BASE = "https://claude.ai"
    const val ORGS_URL = "$BASE/api/organizations"
    fun usageUrl(orgId: String) = "$BASE/api/organizations/$orgId/usage"

    // The page we load in the WebView to (a) let the user log in and
    // (b) silently re-solve the Cloudflare JS challenge to mint cf_clearance.
    const val LOGIN_URL = "$BASE/login"
    const val CHALLENGE_URL = "$BASE/new"

    const val COOKIE_SESSION = "sessionKey"
    const val COOKIE_CF = "cf_clearance"
    const val COOKIE_LAST_ORG = "lastActiveOrg"

    const val REFRESH_INTERVAL_MIN = 15L
    const val WORK_NAME = "claude-usage-refresh"
}
