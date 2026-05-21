#!/bin/bash
set -e

REPO="tbnrfrags123398/Speed_app"
PACKAGE="com.example.speed_app"

# Load GitHub token
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

