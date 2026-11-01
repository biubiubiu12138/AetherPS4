#!/usr/bin/env bash
set -euo pipefail
ROOT=$(pwd)
python3 runtime/scripts/patch-ios-dependencies.py
CHARCONV="$ROOT/runtime/sources/llvm-charconv/libcxx/src"
xcrun --sdk macosx clang++ -std=c++20 -O2 \
  -isysroot "$(xcrun --sdk macosx --show-sdk-path)" \
  -D_LIBCPP_ABI_DO_NOT_EXPORT_TO_CHARS_BASE_10 -I "$CHARCONV" \
  "$CHARCONV/charconv.cpp" "$CHARCONV/ryu/d2fixed.cpp" \
  "$CHARCONV/ryu/d2s.cpp" "$CHARCONV/ryu/f2s.cpp" \
  tests/ios16/charconv_backport.cpp -o /tmp/aether-charconv-test
/tmp/aether-charconv-test
xcrun --sdk iphoneos clang++ -fsyntax-only -std=c++23 -arch arm64 \
  -isysroot "$(xcrun --sdk iphoneos --show-sdk-path)" -miphoneos-version-min=16.2 \
  -include src/platform/ios/libcxx16_compat.h tests/ios16/charconv_backport.cpp
FEX_BUILD="$ROOT/runtime/build/fexcore-ios16"
CORE_BUILD="$ROOT/runtime/build/shadps4-ios"
cmake -S runtime/sources/fexcore-darwin -B "$FEX_BUILD" -G Ninja \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.2 -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_FEXCORE_ONLY=ON -DBUILD_FEXCORE_SMOKE=OFF \
  -DBUILD_TESTING=OFF -DBUILD_FEX_LINUX_TESTS=OFF -DBUILD_THUNKS=OFF \
  -DBUILD_FEXCONFIG=OFF -DENABLE_LTO=OFF -DTUNE_CPU=none -DENABLE_CCACHE=OFF \
  -DENABLE_JEMALLOC_GLIBC_ALLOC=OFF -DENABLE_OFFLINE_TELEMETRY=OFF \
  -DENABLE_VIXL_DISASSEMBLER=OFF -DENABLE_VIXL_SIMULATOR=OFF \
  -DENABLE_GDB_SYMBOLS=OFF -DENABLE_ZYDIS=OFF -DENABLE_FEXCORE_PROFILER=OFF
cmake --build "$FEX_BUILD" --target FEXCore Common CommonTools JemallocLibs --parallel 3
mkdir -p runtime/build/host-tools
xcrun --sdk macosx clang++ -O2 \
  -isysroot "$(xcrun --sdk macosx --show-sdk-path)" \
  externals/dear_imgui/misc/fonts/binary_to_compressed_c.cpp \
  -o runtime/build/host-tools/imgui-font-embed
cmake -S . -B "$CORE_BUILD" -G Ninja \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.2 -DCMAKE_BUILD_TYPE=Release \
  -DIMGUI_FONT_EMBED_EXECUTABLE="$ROOT/runtime/build/host-tools/imgui-font-embed" \
  -DALLOWS_ONESHOT_TIMERS_WITH_TIMEOUT_ZERO=OFF \
  -DENABLE_SHADPS4_IOS_LIB=ON -DENABLE_FEX_GUEST_CPU=ON \
  -DENABLE_DISCORD_RPC=OFF -DENABLE_UPDATER=OFF \
  -DFEXCORE_GUEST_CPU_SOURCE_DIR="$ROOT/runtime/sources/fexcore-darwin" \
  -DFEXCORE_GUEST_CPU_BUILD_DIR="$FEX_BUILD"
cmake --build "$CORE_BUILD" --target shadps4_ios --parallel 3 -- -k 0
mkdir -p "$CORE_BUILD/fexcore-ios-libs"
find "$FEX_BUILD" -name '*.a' -exec cp {} "$CORE_BUILD/fexcore-ios-libs/" \;
ruby generate_project.rb
xcodebuild -project AetherPS4-iOS/AetherPS4-iOS.xcodeproj \
  -scheme AetherPS4-iOS -configuration Release -sdk iphoneos \
  -destination 'generic/platform=iOS' -derivedDataPath runtime/build/ios16-derived \
  IPHONEOS_DEPLOYMENT_TARGET=16.2 CODE_SIGNING_ALLOWED=NO build
OUT="$ROOT/runtime/build/ios16-output"
mkdir -p "$OUT/Payload"
cp -R runtime/build/ios16-derived/Build/Products/Release-iphoneos/AetherPS4-iOS.app "$OUT/Payload/"
APP="$OUT/Payload/AetherPS4-iOS.app"
cp "$ROOT/runtime/sources/llvm-charconv/libcxx/LICENSE.TXT" "$APP/LLVM-LICENSE.txt"
for framework in "$APP"/Frameworks/*.framework; do
  codesign --force --sign - "$framework"
done
for library in "$APP"/Frameworks/*.dylib; do
  codesign --force --sign - "$library"
done
codesign --force --sign - --entitlements "$ROOT/AetherPS4-iOS/AetherPS4-iOS.entitlements" "$APP"
codesign -d --entitlements :- "$APP"
xcrun vtool -show-build "$APP/AetherPS4-iOS"
cd "$OUT"
zip -qry AetherPS4-iOS16.2-experimental.ipa Payload
