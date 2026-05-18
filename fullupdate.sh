#!/bin/bash
set -e

REPO="tbnrfrags123398/Speed_app"
PACKAGE="com.example.speed_app"

# Load GitHub token safely
if [[ ! -f ~/.github_token ]]; then
    echo "❌ ERROR: ~/.github_token not found."
    echo "Create it with: nano ~/.github_token"
    exit 1
fi

GITHUB_TOKEN=$(cat ~/.github_token)

echo "🚀 Starting GitHub API auto-update..."

# -------------------------------
# 1. GET LATEST WORKFLOW RUN
# -------------------------------
echo "🔍 Fetching latest workflow run..."
RUN_DATA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/runs?branch=main&per_page=5")

RUN_ID=$(echo "$RUN_DATA" | grep '"id"' | head -1 | sed 's/[^0-9]*//g')
RUN_STATUS=$(echo "$RUN_DATA" | grep '"status"' | head -1 | sed 's/.*"status": "\(.*\)".*/\1/')
RUN_CONCLUSION=$(echo "$RUN_DATA" | grep '"conclusion"' | head -1 | sed 's/.*"conclusion": "\(.*\)".*/\1/')

echo "📦 Latest run ID: $RUN_ID"
echo "📌 Status: $RUN_STATUS"
echo "📌 Conclusion: $RUN_CONCLUSION"

# -------------------------------
# 2. HANDLE FAILED RUN → AUTO REBUILD
# -------------------------------
if [[ "$RUN_CONCLUSION" == "failure" || "$RUN_CONCLUSION" == "cancelled" ]]; then
    echo "❌ Latest run failed — triggering auto rebuild..."

    date > rebuild.txt
    git add rebuild.txt
    git commit -m "Auto rebuild $(date)"
    git push

    echo "⏳ Waiting for rebuild to finish..."
    sleep 10

    # Poll until success
    for i in {1..40}; do
        RUN_DATA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$REPO/actions/runs?branch=main&per_page=5")

        RUN_ID=$(echo "$RUN_DATA" | grep '"id"' | head -1 | sed 's/[^0-9]*//g')
        RUN_STATUS=$(echo "$RUN_DATA" | grep '"status"' | head -1 | sed 's/.*"status": "\(.*\)".*/\1/')
        RUN_CONCLUSION=$(echo "$RUN_DATA" | grep '"conclusion"' | head -1 | sed 's/.*"conclusion": "\(.*\)".*/\1/')

        echo "🔍 Check $i: Status=$RUN_STATUS Conclusion=$RUN_CONCLUSION"

        if [[ "$RUN_CONCLUSION" == "success" ]]; then
            echo "🎉 Rebuild succeeded!"
            break
        fi

        sleep 15
    done
fi

# -------------------------------
# 3. WAIT IF RUN IS STILL IN PROGRESS
# -------------------------------
if [[ "$RUN_STATUS" == "in_progress" || "$RUN_STATUS" == "queued" ]]; then
    echo "⏳ Build still running — waiting..."

    for i in {1..40}; do
        RUN_DATA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$REPO/actions/runs?branch=main&per_page=5")

        RUN_STATUS=$(echo "$RUN_DATA" | grep '"status"' | head -1 | sed 's/.*"status": "\(.*\)".*/\1/')
        RUN_CONCLUSION=$(echo "$RUN_DATA" | grep '"conclusion"' | head -1 | sed 's/.*"conclusion": "\(.*\)".*/\1/')

        echo "🔍 Check $i: Status=$RUN_STATUS Conclusion=$RUN_CONCLUSION"

        if [[ "$RUN_CONCLUSION" == "success" ]]; then
            echo "🎉 Build finished successfully!"
            break
        fi

        sleep 15
    done
fi

# -------------------------------
# 4. DOWNLOAD ARTIFACT
# -------------------------------
echo "🔍 Fetching artifacts..."
ARTIFACT_INFO=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/artifacts")

ARTIFACT_ID=$(echo "$ARTIFACT_INFO" | grep '"id"' | head -1 | sed 's/[^0-9]*//g')
ARTIFACT_NAME=$(echo "$ARTIFACT_INFO" | grep '"name"' | head -1 | sed 's/.*"name": "\(.*\)".*/\1/')

echo "📦 Artifact: $ARTIFACT_NAME (ID: $ARTIFACT_ID)"

echo "📥 Downloading artifact ZIP..."
curl -L -H "Authorization: token $GITHUB_TOKEN" \
    -o artifact.zip \
    "https://api.github.com/repos/$REPO/actions/artifacts/$ARTIFACT_ID/zip"

echo "📦 Unzipping..."
rm -f *.apk
unzip -o artifact.zip

APK_FILE=$(find . -name "*.apk" | head -1)

# -------------------------------
# 5. DEVICE SEARCH (FULL LOGIC)
# -------------------------------
echo "📱 Preparing to install APK: $APK_FILE"
echo "📱 Checking for connected device..."

for i in {1..15}; do
    DEVICE_STATE=$(adb devices | sed -n '2p' | awk '{print $2}')

    if [[ "$DEVICE_STATE" == "device" ]]; then
        echo "✅ Device detected and authorized."
        break
    fi

    if [[ "$DEVICE_STATE" == "unauthorized" ]]; then
        echo "⚠️ Device detected but unauthorized."
        echo "👉 Tap **Allow USB debugging** on your phone."
        sleep 2
        continue
    fi

    echo "⏳ Waiting for device... ($i/15)"
    sleep 2
done

DEVICE_STATE=$(adb devices | sed -n '2p' | awk '{print $2}')
if [[ "$DEVICE_STATE" != "device" ]]; then
    echo "❌ No authorized device found."
    echo "👉 Make sure:"
    echo "   - USB debugging is ON"
    echo "   - Cable is connected"
    echo "   - You tapped 'Allow' on your phone"
    exit 1
fi

# -------------------------------
# 6. INSTALL APK
# -------------------------------
echo "🗑️ Uninstalling old version (if exists)..."
adb uninstall $PACKAGE || true

echo "📱 Installing new APK..."
adb install -r "$APK_FILE"

echo "🚀 Launching app..."
adb shell monkey -p $PACKAGE 1

# -------------------------------
# 7. VERSION CHECK
# -------------------------------
echo "🔎 Checking installed version..."

APK_VERSION=$(aapt dump badging "$APK_FILE" 2>/dev/null | grep versionName | sed "s/.*versionName='\([^']*\)'.*/\1/")
APK_CODE=$(aapt dump badging "$APK_FILE" 2>/dev/null | grep versionCode | sed "s/.*versionCode='\([^']*\)'.*/\1/")

DEVICE_VERSION=$(adb shell dumpsys package $PACKAGE | grep versionName | sed "s/.*versionName=//")
DEVICE_CODE=$(adb shell dumpsys package $PACKAGE | grep versionCode | sed "s/.*versionCode=//")

echo "📦 APK version: $APK_VERSION (code $APK_CODE)"
echo "📱 Installed version: $DEVICE_VERSION (code $DEVICE_CODE)"

if [[ "$APK_VERSION" == "$DEVICE_VERSION" && "$APK_CODE" == "$DEVICE_CODE" ]]; then
    echo "✅ Device is running the latest version!"
else
    echo "⚠️ Version mismatch — device may not have the newest build."
fi

