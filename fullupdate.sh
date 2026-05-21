#!/bin/bash
set -e

echo "🔧 Auto-fixing Android build files before pushing..."

fix_file() {
    FILE=$1

    # Kotlin version
    sed -i 's/ext.kotlin_version = .*/ext.kotlin_version = "1.9.22"/' $FILE || true

    # JVM target
    sed -i 's/jvmTarget = .*/jvmTarget = "17"/' $FILE || true
    sed -i 's/JavaVersion.VERSION_1_8/JavaVersion.VERSION_17/' $FILE || true

    # compileSdk
    sed -i 's/compileSdk = .*/compileSdk = 34/' $FILE || true

    # AGP version
    sed -i 's/com.android.tools.build:gradle:.*/com.android.tools.build:gradle:8.2.1"/' $FILE || true
}

# Patch all Android build files
fix_file android/build.gradle
fix_file android/app/build.gradle
fix_file android/gradle.properties

# Patch Gradle wrapper
sed -i 's/distributionUrl=.*/distributionUrl=https\:\/\/services.gradle.org\/distributions\/gradle-8.2-bin.zip/' \
    android/gradle/wrapper/gradle-wrapper.properties || true

echo "✅ Android build files patched locally."

# -------------------------------
# VERSION CHECKER
# -------------------------------
echo "🔎 Checking versions..."

KOTLIN_LOCAL=$(grep -oP 'kotlin_version = "\K[^"]+' android/build.gradle || echo "unknown")
JVM_LOCAL=$(grep -oP 'jvmTarget = "\K[^"]+' android/app/build.gradle || echo "unknown")
SDK_LOCAL=$(grep -oP 'compileSdk = \K[0-9]+' android/app/build.gradle || echo "unknown")

echo "📌 Kotlin: $KOTLIN_LOCAL"
echo "📌 JVM: $JVM_LOCAL"
echo "📌 compileSdk: $SDK_LOCAL"

if [[ "$KOTLIN_LOCAL" != "1.9.22" || "$JVM_LOCAL" != "17" || "$SDK_LOCAL" != "34" ]]; then
    echo "⚠️ Version mismatch detected — patching again..."
    fix_file android/build.gradle
    fix_file android/app/build.gradle
    fix_file android/gradle.properties
    echo "🔁 Re-patched."
else
    echo "✅ All versions correct."
fi

# -------------------------------
# GitHub token + repo setup
# -------------------------------
REPO="tbnrfrags123398/Speed_app"
PACKAGE="com.example.speed_app"

if [[ ! -f ~/.github_token ]]; then
    echo "❌ ERROR: ~/.github_token not found."
    echo "Create it with: nano ~/.github_token"
    exit 1
fi

GITHUB_TOKEN=$(cat ~/.github_token)

echo "🚀 Starting GitHub Auto-Updater..."

# -------------------------------
# 1. GET LATEST WORKFLOW RUN
# -------------------------------
echo "🔍 Checking latest workflow run..."

RUN_DATA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/runs?branch=main&per_page=1")

RUN_ID=$(echo "$RUN_DATA" | jq -r '.workflow_runs[0].id')
RUN_STATUS=$(echo "$RUN_DATA" | jq -r '.workflow_runs[0].status')
RUN_CONCLUSION=$(echo "$RUN_DATA" | jq -r '.workflow_runs[0].conclusion')

echo "📦 Run ID: $RUN_ID"
echo "📌 Status: $RUN_STATUS"
echo "📌 Conclusion: $RUN_CONCLUSION"

# -------------------------------
# 2. AUTO-REBUILD IF FAILED
# -------------------------------
if [[ "$RUN_CONCLUSION" == "failure" || "$RUN_CONCLUSION" == "cancelled" ]]; then
    echo "❌ Last build failed — triggering rebuild..."

    echo "$(date)" > rebuild.txt
    git add rebuild.txt
    git commit -m "Auto rebuild $(date)"
    git push

    echo "⏳ Waiting for rebuild to start..."
    sleep 10
fi

# -------------------------------
# 3. WAIT FOR BUILD TO FINISH
# -------------------------------
echo "⏳ Waiting for GitHub Actions to finish..."

for i in {1..60}; do
    RUN_DATA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO/actions/runs?branch=main&per_page=1")

    RUN_STATUS=$(echo "$RUN_DATA" | jq -r '.workflow_runs[0].status')
    RUN_CONCLUSION=$(echo "$RUN_DATA" | jq -r '.workflow_runs[0].conclusion')

    echo "🔍 Check $i: Status=$RUN_STATUS Conclusion=$RUN_CONCLUSION"

    if [[ "$RUN_STATUS" == "completed" && "$RUN_CONCLUSION" == "success" ]]; then
        echo "🎉 Build completed successfully!"
        break
    fi

    sleep 5
done

# -------------------------------
# 4. DOWNLOAD ARTIFACT
# -------------------------------
echo "🔍 Fetching artifact list..."

ARTIFACTS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/artifacts")

ARTIFACT_ID=$(echo "$ARTIFACTS" | jq -r '.artifacts[0].id')
ARTIFACT_NAME=$(echo "$ARTIFACTS" | jq -r '.artifacts[0].name')

echo "📦 Artifact: $ARTIFACT_NAME (ID: $ARTIFACT_ID)"

echo "📥 Downloading artifact..."
curl -L -H "Authorization: token $GITHUB_TOKEN" \
    -o artifact.zip \
    "https://api.github.com/repos/$REPO/actions/artifacts/$ARTIFACT_ID/zip"

echo "📦 Unzipping..."
rm -f *.apk
unzip -o artifact.zip >/dev/null

APK_FILE=$(find . -name "*.apk" | sort | head -1)

echo "📱 APK found: $APK_FILE"

# -------------------------------
# 5. DEVICE DETECTION
# -------------------------------
echo "📱 Checking for connected Android device..."

for i in {1..20}; do
    DEVICE_STATE=$(adb devices | sed -n '2p' | awk '{print $2}')

    if [[ "$DEVICE_STATE" == "device" ]]; then
        echo "✅ Device connected and authorized."
        break
    fi

    if [[ "$DEVICE_STATE" == "unauthorized" ]]; then
        echo "⚠️ Device unauthorized — tap 'Allow USB debugging' on your phone."
        sleep 2
        continue
    fi

    echo "⏳ Waiting for device... ($i/20)"
    sleep 2
done

DEVICE_STATE=$(adb devices | sed -n '2p' | awk '{print $2}')
if [[ "$DEVICE_STATE" != "device" ]]; then
    echo "❌ No authorized device found."
    exit 1
fi

# -------------------------------
# 6. INSTALL APK
# -------------------------------
echo "🗑️ Uninstalling old version..."
adb uninstall $PACKAGE >/dev/null 2>&1 || true

echo "📱 Installing new APK..."
adb install -r "$APK_FILE"

echo "🚀 Launching app..."
adb shell monkey -p $PACKAGE 1 >/dev/null 2>&1

# -------------------------------
# 7. VERSION CHECK
# -------------------------------
echo "🔎 Checking installed version..."

APK_VERSION=$(aapt dump badging "$APK_FILE" 2>/dev/null | grep versionName | sed "s/.*versionName='\([^']*\)'.*/\1/")
APK_CODE=$(aapt dump badging "$APK_FILE" 2>/dev/null | grep versionCode | sed "s/.*versionCode='\([^']*\)'.*/\1/")

DEVICE_VERSION=$(adb shell dumpsys package $PACKAGE | grep versionName | sed "s/.*versionName=//")
DEVICE_CODE=$(adb shell dumpsys package $PACKAGE | grep versionCode | sed "s/.*versionCode=//")

echo "📦 APK version: $APK_VERSION ($APK_CODE)"
echo "📱 Device version: $DEVICE_VERSION ($DEVICE_CODE)"

if [[ "$APK_VERSION" == "$DEVICE_VERSION" && "$APK_CODE" == "$DEVICE_CODE" ]]; then
    echo "✅ Device is running the latest version!"
else
    echo "⚠️ Version mismatch — something went wrong."
fi

