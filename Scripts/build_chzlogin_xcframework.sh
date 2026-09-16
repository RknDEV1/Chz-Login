#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK_NAME="${SDK_NAME:-iphoneos}"
ARCH="${ARCH:-arm64}"
DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-16.0}"
SDK_PATH="$(xcrun --sdk "$SDK_NAME" --show-sdk-path)"
BUILD_DIR="$ROOT/build"
OBJ_DIR="$BUILD_DIR/obj"
FRAMEWORK_DIR="$BUILD_DIR/ChzLogin.xcframework/ios-arm64/ChzLogin.framework"
INCLUDE_DIR="$ROOT/ChzAuth/Sources"
API_DIR="$ROOT/Vendor/API"

rm -rf "$BUILD_DIR"
mkdir -p "$OBJ_DIR" "$FRAMEWORK_DIR/Headers" "$FRAMEWORK_DIR/Modules"

SOURCES=(
  "$ROOT/Sources/CHZAuthManager.m"
  "$ROOT/Sources/CHZKeychain.m"
  "$ROOT/Sources/CHZLoginViewController.m"
  "$ROOT/Sources/CHZLoginBootstrap.m"
)

for source in "${SOURCES[@]}"; do
  name="$(basename "${source%.m}")"
  xcrun --sdk "$SDK_NAME" clang \
    -arch "$ARCH" \
    -isysroot "$SDK_PATH" \
    -miphoneos-version-min="$DEPLOYMENT_TARGET" \
    -fobjc-arc -fblocks -fmodules \
    -I"$INCLUDE_DIR" -I"$API_DIR" \
    -c "$source" -o "$OBJ_DIR/$name.o"
done

xcrun --sdk "$SDK_NAME" clang++ \
  -arch "$ARCH" \
  -isysroot "$SDK_PATH" \
  -miphoneos-version-min="$DEPLOYMENT_TARGET" \
  -dynamiclib -fobjc-arc -fblocks -ObjC \
  -Wl,-dead_strip -Wl,-x -Wl,-S \
  -Wl,-install_name,@rpath/ChzLogin.framework/ChzLogin \
  "$OBJ_DIR/CHZAuthManager.o" \
  "$OBJ_DIR/CHZKeychain.o" \
  "$OBJ_DIR/CHZLoginViewController.o" \
  "$OBJ_DIR/CHZLoginBootstrap.o" \
  "$API_DIR/libAPIClient.a" \
  -framework Foundation -framework UIKit -framework Security -lc++ \
  -o "$FRAMEWORK_DIR/ChzLogin"

cp "$ROOT/Sources/CHZAuthManager.h" "$FRAMEWORK_DIR/Headers/CHZAuthManager.h"
cp "$ROOT/Sources/CHZKeychain.h" "$FRAMEWORK_DIR/Headers/CHZKeychain.h"
cp "$ROOT/Sources/CHZLoginViewController.h" "$FRAMEWORK_DIR/Headers/CHZLoginViewController.h"

cat > "$FRAMEWORK_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.chzpriv.login.framework</string>
<key>CFBundleName</key><string>ChzLogin</string>
<key>CFBundleExecutable</key><string>ChzLogin</string>
<key>CFBundlePackageType</key><string>FMWK</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
</dict></plist>
PLIST

cat > "$FRAMEWORK_DIR/Modules/module.modulemap" <<'MODULEMAP'
framework module ChzLogin {
  umbrella header "CHZLoginViewController.h"
  export *
  module * { export * }
}
MODULEMAP

RESOURCE_BUNDLE="$FRAMEWORK_DIR/CHZLoginResources.bundle"
mkdir -p "$RESOURCE_BUNDLE"
cp "$ROOT/Resources/CHZPrivLogoFinal.png" "$RESOURCE_BUNDLE/CHZPrivLogoFinal.png"
cp "$ROOT/Resources/discord.png" "$RESOURCE_BUNDLE/discord.png"
cat > "$RESOURCE_BUNDLE/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.chzpriv.login.resources</string>
<key>CFBundleName</key><string>CHZLoginResources</string>
<key>CFBundlePackageType</key><string>BNDL</string>
</dict></plist>
PLIST

cat > "$BUILD_DIR/ChzLogin.xcframework/BuildInfo.txt" <<INFO
IPHONEOS_DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET
SDK_NAME=$SDK_NAME
ARCH=$ARCH
INSTALL_NAME=@rpath/ChzLogin.framework/ChzLogin
INFO

xcrun --sdk "$SDK_NAME" file "$FRAMEWORK_DIR/ChzLogin"
otool -L "$FRAMEWORK_DIR/ChzLogin"
