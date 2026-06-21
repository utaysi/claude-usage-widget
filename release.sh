#!/usr/bin/env bash
#
# Cut a new release: bump version, build the signed APK, tag, and publish to
# GitHub Releases with a stable asset name.
#
#   ./release.sh 1.1
#
# versionName is the argument you pass. versionCode is derived from the git
# commit count, so it is always monotonic without any stored state.
#
# Requires the GitHub CLI (`gh`) authenticated against this repo, plus a
# signing config at .signing/keystore.properties (the whole .signing/ folder
# is gitignored). storeFile is resolved relative to the project root:
#
#   storeFile=.signing/release.keystore
#   storePassword=...
#   keyAlias=claude-usage-widget
#   keyPassword=...

set -euo pipefail

ASSET_NAME="claude-usage-widget.apk"
GRADLE_FILE="app/build.gradle.kts"
APK_OUT="app/build/outputs/apk/release/app-release.apk"

if [[ $# -ne 1 ]]; then
    echo "usage: ./release.sh <versionName>   e.g. ./release.sh 1.1" >&2
    exit 1
fi

VERSION_NAME="$1"
TAG="v${VERSION_NAME}"

if [[ ! -f .signing/keystore.properties ]]; then
    echo "error: .signing/keystore.properties not found. See the header of this script for the expected format." >&2
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "error: the GitHub CLI (gh) is required." >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "error: working tree is dirty. Commit or stash first." >&2
    exit 1
fi

# versionCode = number of commits, guaranteed to increase every release.
VERSION_CODE="$(git rev-list --count HEAD)"

echo "==> Setting versionName=${VERSION_NAME}, versionCode=${VERSION_CODE}"
sed -i -E "s/versionCode = [0-9]+/versionCode = ${VERSION_CODE}/" "$GRADLE_FILE"
sed -i -E "s/versionName = \"[^\"]*\"/versionName = \"${VERSION_NAME}\"/" "$GRADLE_FILE"

echo "==> Building signed release APK"
./gradlew :app:assembleRelease

echo "==> Committing version bump and tagging ${TAG}"
git add "$GRADLE_FILE"
git commit -m "release: ${TAG}"
git tag "$TAG"
git push origin HEAD --tags

echo "==> Publishing GitHub Release ${TAG}"
cp "$APK_OUT" "$ASSET_NAME"
gh release create "$TAG" "$ASSET_NAME" \
    --title "$TAG" \
    --generate-notes
rm -f "$ASSET_NAME"

echo "==> Done. https://github.com/utaysi/claude-usage-widget/releases/tag/${TAG}"
