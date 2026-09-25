# Adding macOS to a React Native app

```sh
npm install --save-dev react-native-macos@npm:react-native-darwin@next
npx react-native-darwin-init
```

Installed *alongside* `react-native`, not instead of it. The app keeps one
codebase and builds for iOS, Android and macOS: `react-native` serves the first
two, this package serves macOS, and Metro picks between them per platform.

`react-native-darwin-init` writes a `macos/` directory and a `metro.config.js`,
and then tells you what to run. It does not run the build itself, and nothing it
writes is generated-looking: the Podfile especially is meant to be edited.

## What it writes

| File | Why |
|---|---|
| `macos/Podfile` | The CocoaPods graph, including `React-UIKitCompat`. |
| `macos/generate-project.rb` | Generates the Xcode project, so there is no `pbxproj` to merge. |
| `macos/<App>/` | `main.m`, `AppDelegate`, `Info.plist`, entitlements. |
| `metro.config.js` | Adds the macOS resolver. Skipped if you already have one. |

## Then

```sh
gem install xcodeproj cocoapods
ruby macos/generate-project.rb
(cd macos && RCT_USE_RN_DEP=1 RCT_USE_PREBUILT_RNCORE=0 pod install)
npx react-native start
xcodebuild -workspace macos/<App>.xcworkspace -scheme <App> \
  -configuration Debug -destination 'platform=macOS' build
```

`RCT_USE_PREBUILT_RNCORE=0` is not optional. Without it CocoaPods resolves
Meta's prebuilt React Core, which is published for iOS only, and the install
fails on a platform mismatch.

## Things that will surprise you

**Both packages are installed, and that is the point.** The macOS support is in
the JS as well as the native code -- `Platform.macos.js`, the view configs, the
platform gates -- so a macOS bundle has to come from this package. The Metro
config `react-native-darwin-init` writes redirects `react-native` onto it, but
only when `platform === 'macos'`; iOS and Android bundles are untouched.

If you already had a `metro.config.js`, that redirect is the part you have to
add yourself -- `getMacOSConfig` does it, and wraps any `resolveRequest` you
already had rather than replacing it.

**The Podfile has no `use_native_modules!`.** It shells out to the community CLI
to autolink third-party native modules, and most do not build for macOS. Add it
when the modules you depend on are known to.

**Pin the packager port if you run more than one project.** `localhost` resolves
to `::1` before `127.0.0.1`, so another Metro already bound to `*:8081` serves
your app a valid, unrelated bundle. The symptom is `"main" has not been
registered`, which sends you looking in entirely the wrong place. Either
`RCT_METRO_HOST_PORT=127.0.0.1:8099` for one run, or
`defaults write <bundle-id> RCT_jsLocation 127.0.0.1:8099` to persist it.
