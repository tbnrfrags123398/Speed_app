#!/bin/bash

set -e

APK_URL="https://nightly.link/tbnrfrags123398/Speed_app/workflows/Build%20Android%20APK/main/app-release.zip"
echo "🚀 Starting full auto-update..."

# ============================================================
# ALWAYS FORCE A NEW BUILD
# ============================================================
echo "// build trigger $(date)" > lib/build_trigger.dart

echo "📁 Adding forced rebuild trigger..."
git add lib/build_trigger.dart

echo "📝 Committing..."
git commit -m "Force rebuild $(date)" || {
  echo "❌ Commit failed."
  exit 1
}

echo "⬆️ Pushing to GitHub..."
git push || {
  echo "❌ Git push failed."
  exit 1
}

# ============================================================
# WAIT FOR GITHUB ACTIONS BUILD
# ============================================================
echo "⏳ Waiting for GitHub Actions build to finish and artifact to be ready..."

MAX_TRIES=15
SLEEP_SECONDS=45
TRY=1
HTTP_CODE=0

while [ $TRY -le $MAX_TRIES ]; do
  echo "🔍 Check $TRY/$MAX_TRIES: probing artifact URL..."
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APK_URL" || echo "000")

  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Artifact is ready! (HTTP $HTTP_CODE)"
    break
  else
    echo "⏳ Not ready yet (HTTP $HTTP_CODE). Waiting ${SLEEP_SECONDS}s..."
    sleep $SLEEP_SECONDS
  fi

  TRY=$((TRY + 1))
done

if [ "$HTTP_CODE" != "200" ]; then
  echo "❌ ERROR: Artifact never became ready after $MAX_TRIES checks."
  exit 1
fi

# ============================================================
# DOWNLOAD + INSTALL
# ============================================================
echo "📥 Downloading newest APK ZIP..."
wget -O app-release.zip "$APK_URL"

if [ ! -s app-release.zip ]; then
  echo "❌ ERROR: ZIP download failed. File is empty."
  exit 1
fi

echo "📦 Unzipping APK..."
unzip -o app-release.zip

# The artifact always extracts to app-release.apk
mv app-release.apk latest.apk

echo "🗑️ Uninstalling old version..."
adb uninstall com.example.speed_app || echo "ℹ️ Old app not installed, continuing..."

echo "📦 Installing new APK..."
adb install latest.apk || {
  echo "❌ APK install failed."
  exit 1
}

# ============================================================
# AUTO-LAUNCH APP
# ============================================================
echo "🚀 Launching Speed HUD..."
adb shell monkey -p com.example.speed_app 1

echo "🎉 DONE! Your app is fully updated, installed, and launched."
