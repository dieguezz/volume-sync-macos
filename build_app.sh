.#!/bin/bash

APP_NAME="VolumeSync"
BUILD_DIR=".build/release"
OUTPUT_DIR="dist"
APP_BUNDLE="${OUTPUT_DIR}/${APP_NAME}.app"

echo "🚀 Building ${APP_NAME}..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed."
    exit 1
fi

echo "📦 Creating App Bundle..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy Binary
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Copy Info.plist
cp "Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Generate Icon if source exists
if [ -f "AppIconSource.png" ]; then
    if [ ! -f "AppIcon.icns" ]; then
        echo "🎨 Generating AppIcon.icns..."
        chmod +x create_icns.sh
        ./create_icns.sh
    fi
fi

# Copy Icon
if [ -f "AppIcon.icns" ]; then
    echo "🎨 Copying Icon..."
    cp "AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

echo "📝 Signing (Ad-Hoc)..."
# To sign for App Store, you would use: --sign "Apple Distribution: ..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ Done! App is at ${APP_BUNDLE}"
echo "You can move this to /Applications"
