#!/bin/bash

echo "🚀 Starting full auto-update..."

cd ~/Android/cmdline-tools/speed_app

echo "📁 Adding changes..."
git add .

echo "📝 Committing..."
git commit -m "Auto update"

echo "⬆️ Pushing to GitHub..."
git push

echo "⏳ Waiting for GitHub Actions build to finish..."
sleep 25

echo "🔍 Finding newest app-release folder..."
LATEST=$(ls -dt ~/app-release*/ | head -1)

echo "📥 Downloading newest APK from GitHub..."
wget -O "$LATEST/app-release.apk" \
"https://github.com/tbnrfrags123398/Speed_app/releases/latest/download/app-release.apk"

echo "🗑️ Uninstalling old version..."
adb uninstall com.example.speed_app

echo "📦 Installing new APK..."
adb install -r "$LATEST/app-release.apk"

echo "✅ DONE! Your app is fully updated."
