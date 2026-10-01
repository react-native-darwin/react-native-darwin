# Porting the fork to `v0.88.0-rc.3`

**Result: it ports, and the app renders.** I did the whole thing end to end — rebase,
conflict resolution, shim work, `pod install`, `xcodebuild`, launch — on a scratch clone
at `~/Developer/react-native-darwin`, branch `port/0.88.0-rc.3`. The original checkout at
`~/Developer/rn-macos-fork` was not touched.

```
pod install            86 pods, platform :osx
xcodebuild             ** BUILD SUCCEEDED **
runtime                Running "HelloWorld" {"rootTag":11,"fabric":true}, 0 errors
syntax-check           245 / 245 sources parse against the macOS SDK
macos/tests/run.sh     PASS (0 failures)
check-budget.sh        all checks pass, 182 / 200 upstream files
```

The whole port is **a day of work, not a week**. Nothing in 0.88 attacks the fork's
central idea.

---

## 1. The rebase

`v0.88.0-rc.3` is **not** a descendant of `v0.87.1` — the two release branches diverged at
`ce057d6554`. So `git merge-tree` is useless here (it reports 124 conflicted files, almost
all of them 0.87-stable backports). The correct operation is:

```sh
git rebase --onto v0.88.0-rc.3^{commit} v0.87.1^{commit} macos/v0.87.1
```

All **15 commits replayed**. 5 of them conflicted, on **13 code files + README.md**:

| # | Fork commit | Conflicted files |
|---|---|---|
| 4 | `install the pod graph for macOS and close the shim's gaps` | `RCTDeviceInfo.mm` |
| 5 | `the AppKit host app, publishing, and the dual install` | `Button.js`, `Modal.js`, `RCTViewComponentView.mm`, `RCTPlatformColorUtils.h`, `scripts/cocoapods/utils.rb` |
| 7 | `stop the UIKit aliases leaking out of installed headers` | `RCTAppDelegate.h`, `RCTLinkingManager.h`, `RCTViewComponentView.h`, `RCTImagePrimitivesConversions.h`, `RCTFontUtils.h` |
| 9 | `make Alert work, and add promptMacOS and isHighContrastEnabled` | `RCTAccessibilityManager.mm` |
| 12 | `docs: rewrite the README and the roadmap` | `README.md` |

Eleven of the thirteen are **context drift** — upstream added a doc comment, a deprecation
string or an adjacent declaration right where the fork had edited. Keep both sides and move on.
Three needed thought:

- **`RCTDeviceInfo.mm`** — upstream replaced `UIScreen.mainScreen` with "derive the screen
  from the key window, fall back to `UIScreen.screens.firstObject`". The fork's
  `.contentView` guard has to wrap the new shape rather than the old one.
- **`RCTViewComponentView.mm`** — upstream factored `-focus` through a new `-viewToFocus`.
  The fork's `makeFirstResponder:` has to target `viewToFocus`, not `self`.
- **`RCTAccessibilityManager.mm`** — upstream converted the `RCT_EXPORT_METHOD` macros to
  plain methods. The fork's added `getCurrentHighContrastState` has to be rewritten in the
  new style.

### One patch is now obsolete

`Modal.js`. Upstream **deleted** `ModalEventEmitter` and the whole old-renderer
`modalDismissed` path in 0.88, which was the only thing the fork patched in that file.
Drop the hunk; the fork touches one fewer file.

---

## 2. What 0.88 actually breaks: the UIScene lifecycle

This is the only substantive new work, and it is all in one theme. 0.88 routes deep links
and launch options through `UIScene`, and macOS has no scene model. Five files stopped
compiling:

```
Libraries/AppDelegate/RCTAppDelegate.mm                   UISceneConnectionOptions
Libraries/AppDelegate/RCTDefaultReactNativeFactoryDelegate.mm
Libraries/AppDelegate/RCTReactNativeFactory.mm            UIOpenURLContext
Libraries/LinkingIOS/RCTLinkingManager.mm                 UIOpenURLContext
React/Base/RCTUtils.mm                                    delegate.window
```

Four of the five are **rung 1** — grow the shim. `UISceneConnectionOptions` and
`UIOpenURLContext` become empty classes in `macos/UIKitCompat/UIKit/UIKitDefines.h`
(a connection carries nothing when there is no scene to connect), plus
`RCTPlatformScene` / `RCTPlatformOpenURLContext` / `RCTPlatformSceneConnectionOptions`
in the public `RCTPlatformTypes.h` on both branches, because `RCTLinkingManager.h` and
`RCTReactNativeFactory.h` are *installed* headers and the fork's own rule forbids them
naming a UIKit type. Total: ~56 added lines in `macos/`, 10 changed lines across the two
headers.

The fifth is **rung 4**. `RCTKeyWindow()` now falls back to
`RCTSharedApplication().delegate.window`, and `NSApplicationDelegate` has no `window` —
on macOS the app delegate does not own the window. I guarded it with
`#if TARGET_OS_OSX` returning `nil`, which **preserves 0.87.1 behaviour exactly**
(`connectedScenes` is an empty set on macOS, so `RCTKeyWindow()` already returned `nil`
there and callers already fall back to the screen).

> **Worth a follow-up, deliberately not done here.** Returning `NSApp.keyWindow ?: NSApp.mainWindow`
> is the macOS-correct answer and would make `RCTDeviceInfo` report real window dimensions
> instead of screen dimensions. It changes what `RCTDeviceInfo`,
> `RCTPresentedViewController` and the modal path see, so it wants its own commit and a
> runtime check — not a line smuggled into a version bump.

### One more shim line, found only by the real build

`RCTFontUtils.mm` now casts a CoreText attribute through `UIFontDescriptorAttributeName`.
One `#define` to `NSFontDescriptorAttributeName`. See §4 for why the syntax checker missed it.

---

## 3. The §2.4 assumptions all still hold at 0.88.0-rc.3

Verified against the published artifacts, not the podspec text:

| Assumption | Status |
|---|---|
| Hermes ships `destroot/Library/Frameworks/macosx/hermesvm.framework` | ✅ present, `lipo` says `x86_64 arm64` |
| `ReactNativeDependencies.xcframework` ships `macos-arm64_x86_64` | ✅ present (and so does the new `ReactNativeDependenciesHeaders.xcframework`) |
| ≤2 Swift files in Apple-facing directories | ✅ unchanged: `Package.swift`, `RCTSwiftUIContainerView.swift` |
| All podspecs share one `min_supported_versions` helper | ✅ unchanged |
| No new iOS-only JS platform gates for macOS to silently miss | ✅ zero added between the tags |

`MACOS-FORK.md` §2.4 needs `UPSTREAM_TAG = v0.88.0-rc.3` / `UPSTREAM_SHA = 0782c61fe6`.

---

## 4. Two bugs in the fork's own harness, both pre-existing

Neither is caused by 0.88. Both are worth fixing regardless.

**`macos/scripts/syntax-check.sh` is currently broken on `macos/v0.87.1`.** It is missing
two include paths, so it reports **0 / 244 parsed** — every file dies on
`'RCTPlatformTypes/RCTPlatformTypes.h' file not found`. I confirmed this on the unmodified
0.87.1 branch. Two lines:

```sh
-I "$REPO/macos/UIKitCompat/Public"                                    # added by the drop-UIKit-aliases work
-I "$RN/ReactCommon/react/renderer/components/view/platform/macos"     # KeyEvent.h
```

Without the first, nothing parses. Without the second, 24 Fabric component views are
masked. With both, 0.87.1 reads 244/244 and 0.88.0-rc.3 reads 245/245.

**The syntax checker does not cover `ReactCommon/`.** It walks `React/`, `Libraries/` and
`ReactApple/` only. `RCTFontUtils.mm` lives under
`ReactCommon/react/renderer/textlayoutmanager/platform/ios/` — which is exactly why the
only genuine build failure in this whole port got past a "245/245 clean" reading and showed
up in `xcodebuild`. Widening the `find` is a one-line change and buys back the inner loop.

---

## 5. `macos/HelloWorld` needs a dependency bump

Its `package.json` pins the whole `@react-native/*` set at `^0.87.1`. For 0.88:

```
@react-native/*     0.87.1    -> 0.88.0-rc.3
react               ^19.2.3   -> ^19.3.0
scheduler           0.27.0    -> 0.28.0
hermes-compiler     ^250829098.0.17 -> 260318099.0.4
metro/-config/-resolver  ^0.83.8 -> ^0.87.1   (was already inconsistent with metro-runtime ^0.87.1)
flow-parser         (new)     0.327.0
```

Minor upstream inconsistency, not ours: `packages/react-native/package.json` wants
`hermes-compiler@260318099.0.4` while `sdks/.hermesv1version` says `hermes-v260318099.0.2`.
The syntax checker reads the latter.

---

## 6. Budget after the port

```
Upstream files modified:  182 / 200     (181 before this work; Modal.js out, RCTUtils.mm in)
Files added by the fork:   27
Platform-gate one-liners:  13
Upstream lines removed:   449 / 600
Commits:                   16 / 15      <- squash the two port commits into the series
```

Every other linter check passes, including `no header outside the private shim declares a
UIKit name` — which is what forced the two installed-header renames in §2.

---

## 7. The work, in order

1. `git rebase --onto v0.88.0-rc.3^{commit} v0.87.1^{commit}` — resolve 13 files, ~2 hours.
2. Drop the obsolete `Modal.js` hunk.
3. Fold the UIScene shim work into commit 7 (`stop the UIKit aliases leaking out of
   installed headers`) and the `RCTUtils.mm` guard into commit 4 (`close the shim's gaps`).
4. Add `UIFontDescriptorAttributeName`.
5. Fix the two `syntax-check.sh` include paths and widen it to `ReactCommon/`.
6. Bump `macos/HelloWorld/package.json`.
7. Update `MACOS-FORK.md` §2.4 and the measurement block.
8. Re-run: `macos/tests/run.sh`, `macos/scripts/syntax-check.sh`, `macos/ci/check-budget.sh`,
   `pod install`, `xcodebuild`, launch.

Deferred, each worth its own commit:
- Make `RCTKeyWindow()` return a real `NSWindow` on macOS (§2).
- Decide whether the macOS fork should implement the scene entry points at all, or keep
  them compiling-but-inert as they are now.
