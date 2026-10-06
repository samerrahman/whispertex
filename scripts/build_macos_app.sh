#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "🎨 Generating AppIcon.icns if needed..."
if [ ! -f "AppIcon.icns" ]; then
    swift scripts/generate_icon.swift
    iconutil -c icns AppIcon.iconset -o AppIcon.icns
fi

echo "🔨 Compiling WhisperTeX native macOS binary..."
cd "$DIR/macos"
swift build -c release

APP_DIR="$DIR/dist/WhisperTeX.app"
rm -rf "$APP_DIR" "$DIR/dist/WhisperTeX-macos-arm64.zip" "$DIR/dist/WhisperTeX-macos.dmg" "$DIR/dist/dmg_staging"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "📦 Assembling WhisperTeX.app bundle..."
cp .build/release/WhisperTeX "$APP_DIR/Contents/MacOS/WhisperTeX"
chmod +x "$APP_DIR/Contents/MacOS/WhisperTeX"
if [ -f "$DIR/macos/WhisperTeX/AppIcon.icns" ]; then
    cp "$DIR/macos/WhisperTeX/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

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
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleShortVersionString</key>
    <string>0.2.4</string>
    <key>CFBundleVersion</key>
    <string>5</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
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

echo "✍️ Signing application bundle with ad-hoc signature..."
codesign --force --deep --sign - "$APP_DIR"
codesign -vvv "$APP_DIR"

cd "$DIR/dist"
echo "🗜️ Creating WhisperTeX-macos-arm64.zip..."
zip -r -q -y "WhisperTeX-macos-arm64.zip" "WhisperTeX.app"

echo "💿 Preparing DMG staging folder with Applications shortcut..."
DMG_STAGING="$DIR/dist/dmg_staging"
mkdir -p "$DMG_STAGING"
cp -a "$APP_DIR" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

cat <<EOF > "$DMG_STAGING/How to Install.txt"
WhisperTeX for Mac - Quick Installation Guide
=============================================

1. Drag WhisperTeX.app into the Applications shortcut arrow.
2. First time opening on macOS:
   Right-click (or Control-click) WhisperTeX in Applications -> click Open -> click Open.
   (Or in System Settings -> Privacy & Security -> click 'Open Anyway').
3. Look for the '∫' icon in your top menu bar!
4. Press ⌘+Shift+L anywhere across macOS to dictate math directly into any app!

GitHub: https://github.com/samerrahman/whispertex
EOF

echo "💿 Creating WhisperTeX-macos.dmg with drag-to-Applications support..."
hdiutil create -volname "WhisperTeX" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DIR/dist/WhisperTeX-macos.dmg" > /dev/null
rm -rf "$DMG_STAGING"

echo "✅ Build completed successfully!"
ls -lh "$DIR/dist"
