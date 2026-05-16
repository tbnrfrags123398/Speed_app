#!/bin/bash

echo "🚀 Starting full auto-update..."

# Add and commit changes
echo "📁 Adding changes..."
git add .
echo "📝 Committing..."
git commit -m "Auto update"

echo "⬆️ Pushing to GitHub..."
git push

echo "⏳ Waiting for GitHub Actions build to finish..."
sleep 35

echo "📥 Downloading newest APK from GitHub Actions artifact..."

APK_URL="https://nightly.link/tbnrfrags123398/Speed_app/workflows/build/main/app-release.apk"

wget -O latest.apk "$APK_URL"

if [ ! -s latest.apk ]; then
    echo "❌ ERROR: APK download failed. File is empty."
    exit 1
fi

echo "🗑️ Uninstalling old version..."
adb uninstall com.example.speed_app

echo "📦 Installing new APK..."
adb install latest.apk

echo "✅ DONE! Your app is fully updated and installed."
