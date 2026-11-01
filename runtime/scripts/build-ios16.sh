#!/usr/bin/env bash
set -euo pipefail
ROOT=$(pwd)
FEX_BUILD="$ROOT/runtime/build/fexcore-ios16"
CORE_BUILD="$ROOT/runtime/build/shadps4-ios"
cmake -S runtime/sources/fexcore-darwin -B "$FEX_BUILD" -G Ninja \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.2 -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_FEXCORE_ONLY=ON -DBUILD_FEXCORE_SMOKE=OFF \
  -DBUILD_TESTING=OFF -DBUILD_FEX_LINUX_TESTS=OFF -DBUILD_THUNKS=OFF \
  -DBUILD_FEXCONFIG=OFF -DENABLE_LTO=OFF -DTUNE_CPU=none \
  -DENABLE_JEMALLOC_GLIBC_ALLOC=OFF -DENABLE_OFFLINE_TELEMETRY=OFF \
  -DENABLE_VIXL_DISASSEMBLER=OFF -DENABLE_VIXL_SIMULATOR=OFF \
  -DENABLE_GDB_SYMBOLS=OFF -DENABLE_ZYDIS=OFF -DENABLE_FEXCORE_PROFILER=OFF
cmake --build "$FEX_BUILD" --target FEXCore Common CommonTools --parallel 3
cmake -S . -B "$CORE_BUILD" -G Ninja \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.2 -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_SHADPS4_IOS_LIB=ON -DENABLE_FEX_GUEST_CPU=ON \
  -DENABLE_DISCORD_RPC=OFF -DENABLE_UPDATER=OFF \
  -DFEXCORE_GUEST_CPU_SOURCE_DIR="$ROOT/runtime/sources/fexcore-darwin" \
  -DFEXCORE_GUEST_CPU_BUILD_DIR="$FEX_BUILD"
cmake --build "$CORE_BUILD" --target shadps4_ios --parallel 3
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
cd "$OUT"
zip -qry AetherPS4-iOS16.2-experimental.ipa Payload
