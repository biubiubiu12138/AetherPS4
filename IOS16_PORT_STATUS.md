# iOS 16.2 port status

Target: iPhone 14 Pro Max (arm64), iOS 16.2, TrollStore.

## Source changes

- Replaced iOS 17 Observation with ObservableObject / Published and matching SwiftUI ownership and environment injection.
- Replaced iOS 17 onChange, toolbar placements, empty-state view, symbol animation, and hierarchical background styles.
- Set Xcode and its generator to iOS 16.2; removed developer-specific absolute search paths and hardcoded SDK path.
- Added a cloud Swift typecheck against the iOS 16.2 deployment target. This does not link or execute the emulator.

Validation: the complete Swift source set passed Xcode 16.4 typechecking with target arm64-apple-ios16.2 in Actions run 41282133899. This is a frontend compile check, not an app link or device test.

## Native build blocker

The checked-in root CMakeLists.txt is byte-identical to externals/CMakeLists.txt, contains no project or shadps4_ios target, and cannot build the native core. The Xcode project requires runtime/build/shadps4-ios/libshadps4_ios.a and FEXCore libraries that are not included.

Upstream commit 160280112ae4fb140367479e1be463d37917eb9b explicitly states that the shipped core archive is built from a separate Bachata-S4 checkout and copied into this project. Commit 74f94b61b213fbc231b59a3917cb404cbb25e098 temporarily contains a larger CMake file, but the author reverted it as an unrelated build configuration. It must not be treated as a verified build recipe.

A complete release requires recovering that core build recipe, rebuilding all native static libraries for iOS 16.2, linking the actual app, auditing the final Mach-O deployment targets and imports, and testing on the phone. Editing the upstream IPA minimum version alone does not establish compatibility.

Bundled binary metadata: BreakpointJIT minimum iOS 15.0; libvulkan.dylib minimum iOS 13.0. Their runtime behavior on iOS 16.2 remains untested. The core uses the external BreakpointJIT debugger protocol; a generic JIT-ready flag alone is not sufficient to verify that allocation path.

No runnable iOS 16.2 IPA has been produced or claimed by this port.
