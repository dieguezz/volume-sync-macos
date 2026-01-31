#!/bin/bash

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

# Copy Icon (Empty for now, or generate one?)
# We could use the system icon if we had an .icns file.
# cp "Icons.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

echo "📝 Signing (Ad-Hoc)..."
# To sign for App Store, you would use: --sign "Apple Distribution: ..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ Done! App is at ${APP_BUNDLE}"
echo "You can move this to /Applications"
