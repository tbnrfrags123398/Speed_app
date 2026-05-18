#!/bin/bash

set -e

APK_URL="https://nightly.link/tbnrfrags123398/Speed_app/workflows/Build%20Android%20APK/main/app-release.apk"

echo "🚀 Starting full auto-update..."

# Check for changes
if git diff --quiet; then
  echo "ℹ️ No changes to commit. Skipping git commit/push."
else
  echo "📁 Adding changes..."
  git add .

  echo "📝 Committing..."
  git commit -m "Auto update" || {
    echo "❌ Commit failed."
    exit 1
  }

  echo "⬆️ Pushing to GitHub..."
  git push || {
    echo "❌ Git push failed."
    exit 1
  }
fi

echo "⏳ Waiting for GitHub Actions build to finish and artifact to be ready..."

# Poll nightly.link until it returns 200 or timeout
MAX_TRIES=10
SLEEP_SECONDS=60
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

echo "📥 Downloading newest APK from GitHub Actions artifact..."
wget -O latest.apk "$APK_URL"

if [ ! -s latest.apk ]; then
  echo "❌ ERROR: APK download failed. File is empty."
  exit 1
fi

echo "🗑️ Uninstalling old version..."
adb uninstall com.example.speed_app || echo "ℹ️ Old app not installed or uninstall failed, continuing..."

echo "📦 Installing new APK..."
adb install latest.apk || {
  echo "❌ APK install failed."
  exit 1
}

echo "✅ DONE! Your app is fully updated and installed."

