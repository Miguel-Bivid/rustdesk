#!/usr/bin/env bash
# Compila el APK de BividDesk (replica el job build-rustdesk-android del CI).
#
#   branding/build_android.sh [arm64-v8a|armeabi-v7a|x86_64] [config.json]
#
# Por defecto: arm64-v8a y la configuracion ya firmada del repo (branding/custom-full.txt).
# Con config.json se firma ese archivo, lo que necesita branding/private/custom_client.sk.
# Requiere: ANDROID_NDK_HOME (r28c), VCPKG_ROOT, Flutter 3.24.5 parcheado, Rust 1.75,
# cargo-ndk 3.1.2 y flutter_rust_bridge_codegen 1.80.1.
# Sin flutter/android/key.properties el APK se firma con la clave debug (como el CI).
set -euo pipefail

ABI=${1:-arm64-v8a}
CONFIG=${2:-}
cd "$(dirname "$(readlink -f "$0")")/.."

case "$ABI" in
arm64-v8a)   TARGET=aarch64-linux-android;   NDK_SCRIPT=ndk_arm64.sh; LIBCXX=aarch64-linux-android; PLATFORM=android-arm64 ;;
armeabi-v7a) TARGET=armv7-linux-androideabi; NDK_SCRIPT=ndk_arm.sh;   LIBCXX=arm-linux-androideabi; PLATFORM=android-arm ;;
x86_64)      TARGET=x86_64-linux-android;    NDK_SCRIPT=ndk_x64.sh;   LIBCXX=x86_64-linux-android;  PLATFORM=android-x64 ;;
*) echo "ABI no soportada: $ABI" >&2; exit 1 ;;
esac
: "${ANDROID_NDK_HOME:?define ANDROID_NDK_HOME (NDK r28c)}"
: "${VCPKG_ROOT:?define VCPKG_ROOT}"

# 1. Configuracion firmada: build.rs la incrusta en librustdesk.so y aborta si la firma
# no corresponde a branding/custom_client.pub
if [ -z "$CONFIG" ]; then
    export CUSTOM_CLIENT_FILE="$PWD/branding/custom-full.txt"
else
    [ -f branding/private/custom_client.sk ] || { echo "Firmar $CONFIG necesita branding/private/custom_client.sk" >&2; exit 1; }
    python3 branding/sign_custom_client.py sign "$CONFIG"
    export CUSTOM_CLIENT_FILE="$PWD/branding/private/out/$(basename "${CONFIG%.*}").txt"
fi

# 2. Bridge Rust <-> Dart (no esta en git)
(cd flutter && flutter pub get)
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs \
    --dart-output ./flutter/lib/generated_bridge.dart \
    --c-output ./flutter/macos/Runner/bridge_generated.h

# 3. Dependencias C (vcpkg) y libreria Rust
./flutter/build_android_deps.sh "$ABI"
rustup target add "$TARGET"
"./flutter/$NDK_SCRIPT"
JNI=flutter/android/app/src/main/jniLibs/$ABI
mkdir -p "$JNI"
cp "target/$TARGET/release/liblibrustdesk.so" "$JNI/librustdesk.so"
cp "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/$LIBCXX/libc++_shared.so" "$JNI/"

# 4. APK (sin keystore propio se firma con debug; build.gradle se restaura al salir)
GRADLE=flutter/android/app/build.gradle
if [ ! -f flutter/android/key.properties ]; then
    cp "$GRADLE" "$GRADLE.bak"
    trap 'mv -f "$GRADLE.bak" "$GRADLE"' EXIT
    sed -i "s/signingConfigs.release/signingConfigs.debug/g" "$GRADLE"
fi
(cd flutter && flutter build apk --release --target-platform "$PLATFORM" --split-per-abi)

VERSION=$(sed -n 's/^version = "\(.*\)"/\1/p' Cargo.toml | head -n1)
mkdir -p target/dist
cp "flutter/build/app/outputs/flutter-apk/app-$ABI-release.apk" "target/dist/BividDesk-$VERSION-$ABI.apk"
echo "Generado: target/dist/BividDesk-$VERSION-$ABI.apk"
