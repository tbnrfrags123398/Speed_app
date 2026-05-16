#!/bin/bash

echo "🔍 Finding newest APK..."

APK_PATH=$(ls -dt ~/app-release*/ | head -1)/app-release.apk

echo "📦 Using APK: $APK_PATH"

echo "🗑️ Uninstalling old version..."
adb uninstall com.example.speed_app

echo "📥 Installing new APK..."
adb install -r "$APK_PATH"

echo "✅ Update complete!"
