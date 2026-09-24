# HelloWorld (macOS)

The smallest React Native app that runs on macOS, used to prove the fork
actually builds and renders rather than merely parses.

## Running it

```sh
cd macos/HelloWorld
npm install
ruby generate-project.rb          # writes HelloWorld.xcodeproj
RCT_USE_RN_DEP=1 RCT_USE_PREBUILT_RNCORE=0 pod install
node start-metro.js &             # Metro on 127.0.0.1:8081
open build/dd/Build/Products/Debug/HelloWorld.app
```

`RCT_USE_PREBUILT_RNCORE=0` matters: Meta publishes a prebuilt React Core
xcframework, but it has no macOS slice, so core has to build from source.
`RCT_USE_RN_DEP=1` is the opposite case -- the prebuilt dependencies xcframework
*does* ship `macos-arm64_x86_64`, so folly, glog, boost, fmt and SocketRocket
come ready-made.

## Why the project is generated

`generate-project.rb` writes the `.xcodeproj` rather than the fork committing
one. A pbxproj is a merge hazard and this app exists to be rebuilt, not edited.

## Why Metro is started directly

The community CLI's `start` and `bundle` commands are registered by a plugin
that resolves against a *published* react-native. This fork is a path
dependency, so the commands do not appear. `start-metro.js` runs Metro with the
same config instead; the dev server it serves is the one
`RCTBundleURLProvider` asks for.

## What this app is not

It has no native modules and does not call `use_native_modules!`. It is a build
and render check, not a template.
