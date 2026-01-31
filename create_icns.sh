#!/bin/bash

SOURCE="AppIconSource.png"
ICONSET="AppIcon.iconset"

if [ ! -f "$SOURCE" ]; then
    echo "❌ Source icon $SOURCE not found."
    exit 1
fi

mkdir -p "$ICONSET"

# Resize images
sips -z 16 16     --setProperty format png "$SOURCE" --out "${ICONSET}/icon_16x16.png"
sips -z 32 32     --setProperty format png "$SOURCE" --out "${ICONSET}/icon_16x16@2x.png"
sips -z 32 32     --setProperty format png "$SOURCE" --out "${ICONSET}/icon_32x32.png"
sips -z 64 64     --setProperty format png "$SOURCE" --out "${ICONSET}/icon_32x32@2x.png"
sips -z 128 128   --setProperty format png "$SOURCE" --out "${ICONSET}/icon_128x128.png"
sips -z 256 256   --setProperty format png "$SOURCE" --out "${ICONSET}/icon_128x128@2x.png"
sips -z 256 256   --setProperty format png "$SOURCE" --out "${ICONSET}/icon_256x256.png"
sips -z 512 512   --setProperty format png "$SOURCE" --out "${ICONSET}/icon_256x256@2x.png"
sips -z 512 512   --setProperty format png "$SOURCE" --out "${ICONSET}/icon_512x512.png"
sips -z 1024 1024 --setProperty format png "$SOURCE" --out "${ICONSET}/icon_512x512@2x.png"

# Convert to icns
iconutil -c icns "$ICONSET"

# Cleanup
rm -rf "$ICONSET"

echo "✅ Generated AppIcon.icns"
