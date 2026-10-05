#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR/macos"

echo "🔨 Compiling WhisperTeX native macOS binary..."
swift build -c release

APP_DIR="$DIR/dist/WhisperTeX.app"
rm -rf "$APP_DIR" "$DIR/dist/WhisperTeX-macos-arm64.zip" "$DIR/dist/WhisperTeX-macos.dmg"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "📦 Packaging WhisperTeX.app bundle..."
cp .build/release/WhisperTeX "$APP_DIR/Contents/MacOS/WhisperTeX"
chmod +x "$APP_DIR/Contents/MacOS/WhisperTeX"

cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>WhisperTeX</string>
    <key>CFBundleIdentifier</key>
    <string>com.samerrahman.whispertex</string>
    <key>CFBundleName</key>
    <string>WhisperTeX</string>
    <key>CFBundleDisplayName</key>
    <string>WhisperTeX</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.2.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>WhisperTeX requires microphone access to transcribe spoken mathematical formulas.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>WhisperTeX uses Apple Events to paste converted LaTeX equations directly at your cursor.</string>
</dict>
</plist>
EOF

echo "APPL????" > "$APP_DIR/Contents/PkgInfo"

cd "$DIR/dist"
echo "🗜️ Creating WhisperTeX-macos-arm64.zip..."
zip -r -q -y "WhisperTeX-macos-arm64.zip" "WhisperTeX.app"

echo "💿 Creating WhisperTeX-macos.dmg..."
hdiutil create -volname "WhisperTeX" -srcfolder "WhisperTeX.app" -ov -format UDZO "WhisperTeX-macos.dmg" > /dev/null

echo "✅ Build completed successfully!"
ls -lh "$DIR/dist"
