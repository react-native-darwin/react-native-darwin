# MACOS-FORK.md

**The contract for this fork.** It defines what the fork may change, how each change is marked, and
how many commits it may use. Read it before you write code. CI enforces the parts that can be checked
by a machine.

This file lives at the root of the fork repository.

---

## 1. What this fork is

This fork adds AppKit support to React Native. It is a thin layer on top of an unmodified upstream
tag. It is not a long-lived divergent branch.

**Goal.** React Native compiles and runs on macOS with AppKit, using as few changes to upstream
source as possible.

**Status.** Met, at `v0.87.1`: New Architecture, Fabric and Hermes, rendering an
AppKit view tree, in **47 modified upstream files against their 354**. Run it
with `macos/HelloWorld`.

**Non-goal.** Feature parity with `microsoft/react-native-macos`. That fork changes 603 files and
about 23,000 lines in `packages/react-native`. We target fewer than 75 modified upstream files.

**Non-goal.** Mac Catalyst. Upstream already supports it. If Catalyst is enough for a use case, use
upstream directly and do not use this fork.

### The one idea

`react-native-macos` invented new type names (`RCTPlatformView`, `RCTUIView`, `RCTUIColor`). It then
edited 538 upstream files to use them.

We do not invent names. **The macOS SDK contains no `UIKit.framework`, so the UIKit names are free.**
We define real AppKit-backed types that are literally called `UIView`, `UIColor`, `UIScrollView`, and
we serve them from a header directory named `UIKit`. Upstream source keeps its `#import <UIKit/UIKit.h>`
and its `UIView *` declarations, and compiles unchanged.

Every rule below follows from that idea.

---

## 2. Repository model

### 2.1 Layout

The fork is an **overlay**, not a monorepo fork.

```
macos/                        Everything we own. Never conflicts on rebase.
  UIKitCompat/
    UIKit/                    The shim. Served on the header search path.
      UIKit.h                 Umbrella. Satisfies #import <UIKit/UIKit.h>.
      UIView.h / .m           Includes RCTPlatformView. See section 4.5.
      UIScrollView.h / .m
      ...
    MobileCoreServices/       Forwards to CoreServices, same trick as UIKit.
    RCTPlatformViewCompat.h   Force-included prelude (-include).
    macos-excludes.txt        Files the macOS build does not ship.
    React-UIKitCompat.podspec
  metro-config.js             Resolves macos -> ios -> shared for Metro.
  HelloWorld/                 The AppKit host app. NSApplication, NSWindow.
  scripts/
    syntax-check.sh           The inner loop while porting.
    generate-codegen.sh
    publish.sh                npm publish without renaming the repo. See 2.6.
  tests/
    UIKitCompatTest.m         Behaviour, under -Werror.
    check-no-self-recursion.py
    run.sh
  ci/check-budget.sh          Budget linter.
MACOS-FORK.md                 This file.
.github/workflows/
  macos-publish.yml           Ours, despite the location. GitHub requires
                              workflows here, so fork-owned ones are marked by
                              a `macos-` prefix and excluded from the budget.
```

`macos/UIKitCompat/` and `macos/metro-config.js` are the only two things a
consuming app needs at runtime. `macos/scripts/publish.sh` vendors both into the
npm package.

Upstream stays where upstream put it. We add no top-level directories other than `macos/`.

### 2.2 What we do not fork

We do not carry, edit, or regenerate any of the following:

- `docsite/`
- `.github/` and `.ado/` CI beyond one macOS build job
- `yarn.lock` and `Gemfile.lock` churn
- Jest, Flow, TypeScript, or C++ API snapshots
- release tooling and version bumping
- `packages/rn-tester` changes beyond one macOS target

In `react-native-macos`, these account for about 40,000 of 64,000 added lines, and roughly half of all
recent commits. We do not pay that cost.

### 2.3 Package name

**The package stays `react-native`.** Do not rename it to `react-native-macos`.

The rename is what forces `react-native-macos` to fork Hermes version resolution, edit
`require.resolve` calls in podspecs, and manage peer-dependency drift. Keeping the name avoids all of it.

### 2.4 Upstream pin

Track one upstream tag at a time. Record it here on every upgrade.

```
UPSTREAM_TAG = v0.88.0-rc.3
UPSTREAM_SHA = 0782c61fe6
```

Verified present at this tag, against the published artifacts rather than the podspec text:
- Hermes tarball ships `destroot/Library/Frameworks/macosx/hermesvm.framework`, universal x86_64+arm64.
- `ReactNativeDependencies.xcframework` ships a `macos-arm64_x86_64` slice, and so does the
  `ReactNativeDependenciesHeaders.xcframework` the syntax checker reads.
- 2 Swift files in Apple-facing directories, so no Swift module-map problem.
- All podspecs share one `min_supported_versions` helper.
- No new iOS-only JS platform gate was added between the tags, so nothing new silently
  takes the Android path.

`v0.88.0-rc.3` is **not** a descendant of `v0.87.1` -- the release branches diverged at
`ce057d6554`. `git merge-tree` is therefore useless for sizing an upgrade; it reports the
0.87-stable backports as conflicts. Rebase, as §7 says.

The cost of this upgrade, and the two harness bugs it exposed, are in
[`macos/PORT-0.88.md`](macos/PORT-0.88.md).

### 2.5 Branch model

```
upstream/v0.87.1  ──  macos/v0.87.1   (our commits, rebased — never merged)
```

**Rebase onto new upstream tags. Never merge.** Merging produces the snapshot-regeneration tax
described in §2.2. Rebasing keeps the commit series readable and keeps the budget measurable.

### 2.6 Publishing to npm

**The package is not renamed in the repository. It is renamed at publish time.**

Renaming in the tree would grow the diff against the upstream tag for no
functional reason, and every rebase onto a new tag would conflict on it.
`macos/scripts/publish.sh` does the rename, packs, verifies, and restores the
tree. It is the only thing that knows the published name.

Only one package needs publishing. All the fork's changes live in
`packages/react-native`, and every one of its dependencies is an upstream
`@react-native/*` package at an exact version that this fork does not touch.

Three things the script has to do beyond rewriting `name`:

1. Vendor `macos/UIKitCompat/` and `macos/metro-config.js` into the package.
   npm cannot pack a path outside the package directory.
2. Add `macos` to the `files` allowlist, and `./macos/metro-config` to
   `exports`. `exports` is a gate: a subpath missing from it is unreachable
   even when it is present in the tarball.
3. Verify the tarball before anything leaves the machine -- in particular that
   `scripts/cocoapods/helpers.rb` can still resolve `macos-excludes.txt`, which
   is the one path that differs between the two layouts.

`helpers.rb` and `React-UIKitCompat.podspec` both accept either layout, so
nothing is patched during publish.

**Consume the package under the upstream name**, with an npm alias:

```json
"dependencies": { "react-native": "npm:react-native-darwin@0.87.1" }
```

npm installs the tarball at `node_modules/react-native`. That is required, not
cosmetic: `@react-native/metro-config` hardcodes
`require.resolve("react-native/setup-env")` and an `assetRegistryPath` of
`"react-native/asset-registry"`, and `@react-native/assets-registry` imports
from `'react-native'`. Those packages are upstream and unforked, so the
*install path* is what has to match, not the published name. The alias also
means an app cannot depend on this fork and upstream React Native at once --
acceptable for a macOS-only app, and the same constraint react-native-macos has.

#### Trusted publishing

Publishing runs from `.github/workflows/macos-publish.yml` using npm trusted
publishing (OIDC). **There is no `NPM_TOKEN`.** GitHub mints a short-lived token
scoped to that one workflow, npm exchanges it for publish rights, and provenance
attestations are generated automatically.

Four things this depends on, each of which fails the publish if wrong:

| Requirement | Where |
|---|---|
| `permissions: id-token: write` on the publishing job | `macos-publish.yml` |
| npm >= 11.5.1, Node >= 22.14.0 | the workflow installs `npm@latest` |
| `repository.url` matches the GitHub repo exactly | set by `publish.sh` |
| The workflow **filename** matches the trusted-publisher setting | npmjs.com |

The filename coupling is the sharp edge: the trusted publisher is registered
against `macos-publish.yml` by name, so renaming or moving the workflow breaks
publishing until the npm setting is updated to match.

The configuration, already in place on npmjs.com under the package's
Settings -> Trusted publishing:

```
Publisher          GitHub Actions
Organization/user  gabrieldonadel
Repository         react-native-macos
Workflow filename  macos-publish.yml
Environment        (empty)
Allowed actions    npm publish, npm stage publish
```

`npm publish` has to be ticked explicitly; only `npm stage publish` is granted
by default.

**A trusted publisher cannot be configured for a package that does not exist
yet** -- the settings page appears only once something has been published under
the name. `react-native-darwin` was seeded with a placeholder 0.0.1, so that
step is behind us. It matters again only if the fork is ever republished under a
different name, in which case the first version goes out manually with a token
that is revoked straight after:

```sh
npm login
./macos/scripts/publish.sh --publish --name <new-name>
```

Self-hosted runners are not supported, and provenance is not generated for
private repositories.

#### The name

`react-native-darwin`, because npm rejects anything whose name, lowercased
and stripped of `.`, `_` and `-`, lands within one character of an existing
package. That is a typo-squatting guard, and it is why the obvious names are
gone:

```
react-native-appkit  -> reactnativeappkit   collides with react-native-app-kit
react-native-osx     -> reactnativeosx      one character from react-native-os
```

Neither blocker has anything to do with macOS. A scoped name would sidestep the
check entirely if a better one is ever wanted.

---

## 3. The `[macOS]` annotation

Every change to an upstream file carries a `[macOS]` marker. No exceptions. The marker is what makes
the fork auditable and what lets CI measure it.

### 3.1 Syntax

**Single line.** Marker at end of line.

```objc
UIView *container = self.contentView; // [macOS]
```

**Block.** Open and close markers on their own lines.

```objc
// [macOS
- (void)setUpTrackingArea
{
  ...
}
// macOS]
```

**Preprocessor guard.** Marker attaches to the `#if` and the `#endif`.

```objc
#if TARGET_OS_OSX // [macOS
  return clipView ?: self.window.contentView;
#else // macOS]
  return clipView ?: self.window;
#endif
```

**New whole file.** One marker below the licence header.

```objc
/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * ...
 */

// [macOS]
```

**JavaScript, Flow, TypeScript.** Same markers, `//` comments.

**Ruby and shell.** Same markers, `#` comments.

### 3.2 When a marker is required

A marker is required on every added, changed, or removed line in any file that upstream owns.

### 3.3 When a marker is forbidden

Do not use markers inside `macos/`. That whole directory is ours. Markers there are noise.

### 3.4 Why the marker matters

The marker is not decoration. Three things depend on it:

1. `git diff` review — a reviewer can confirm the change is macOS-scoped in one pass.
2. The rebase — an unmarked change is a change nobody can classify a year from now.
3. The CI linter (§6) — it rejects any unmarked hunk in an upstream file.

---

## 4. Change rules

### 4.1 The escape-hatch ladder

A file fails to compile for macOS. Apply the first remedy that works. **Do not skip down the ladder.**

| # | Remedy | Cost to us | Use when |
|---|---|---|---|
| 1 | **Grow the shim** in `macos/UIKitCompat/` | Zero upstream diff | Almost always. This is the default. |
| 2 | **Exclude the file** from the macOS pod | Zero upstream diff | The file is dev-only or not shipping yet. |
| 3 | **Stub the file** with a no-op in `macos/` | Zero upstream diff | Core code holds a reference to something we excluded. |
| 4 | **Edit the upstream file** | Counts against budget | Nothing above can express it. |

Rung 4 requires a `[macOS]` marker and consumes budget. Treat it as a last resort, and say in the
commit message why rungs 1 to 3 did not work.

### 4.2 Forbidden in upstream files

These are rejected in review, regardless of budget:

- **Renaming a UIKit type.** No `RCTUIView`, no `RCTUIColor`, no `RCTPlatformImage`. Extend the
  shim instead. The single exception is `RCTPlatformView`, and only in the two positions
  described in §4.5 — never as a pointer type.
- **Reformatting.** No clang-format runs, no import reordering, no whitespace fixes.
- **Changing iOS behaviour.** Any line reachable on iOS must behave exactly as upstream does.
  If a change is not inside `#if TARGET_OS_OSX`, justify it in the commit message.
- **Deleting upstream code.** Guard it with `#if !TARGET_OS_OSX` instead. Target zero deleted lines.
- **Touching test snapshots, lockfiles, or generated API files.**

### 4.3 Preferred shapes in upstream files

Ranked best to worst.

1. **No change.** The shim absorbed it.
2. **A `#if TARGET_OS_OSX` block that adds macOS-only code.** iOS is untouched by construction.
3. **A `#if TARGET_OS_OSX` / `#else` pair.** The iOS branch must be byte-identical to the original line.
4. **An unguarded change.** Requires explicit justification.

### 4.4 Shim design rules

Three tiers. Put each symbol in the highest tier that works.

| Tier | Mechanism | Count | Example |
|---|---|---:|---|
| 1 | `@compatibility_alias` + a category for missing methods | ~152 symbols | `@compatibility_alias UIFont NSFont;` |
| 2 | `enum` / `#define` constants | ~200 symbols | `UIAccessibilityTraitButton`, `UIKeyModifierCommand` |
| 3 | A real class, subclassing the AppKit equivalent | ~15 types | `@interface UIView : NSView` |

Use `@compatibility_alias`, not `#define`. It is a real type alias the compiler understands, so
diagnostics stay readable and categories attach correctly.

Check AppKit before writing a Tier 3 method. AppKit already provides more UIKit-shaped API than people
expect — `NSView.clipsToBounds` and `NSColor.colorWithRed:green:blue:alpha:` both exist.

`react-native-macos`'s `React/Base/RCTUIKit.h` and `React/Base/macOS/RCTUIKit.m` (1,747 lines, MIT) are
a direct reference implementation for all three tiers. Port from them, renaming `RCTPlatformView` to
`UIView` and so on. Keep their copyright headers.

### 4.5 `UIView` is an alias; `RCTPlatformView` is the class

`UIView` is `@compatibility_alias UIView NSView`, not a subclass.

The reason is single inheritance. In UIKit, `UIScrollView` **is** a `UIView`. On
macOS it cannot be — it has to derive from `NSScrollView` to scroll. If `UIView`
were its own `NSView` subclass, `UIScrollView` would be a *sibling* of it, and
every upstream signature taking a `UIView *` would reject a scroll view. No
arrangement of single inheritance reproduces both hierarchies.

So the alias follows AppKit's truth: on macOS the common supertype of every view
is `NSView`. That makes all ~322 `UIView *` declarations in upstream source
correct exactly as written.

What an alias cannot carry is behaviour. A plain `NSView` is not flipped, is not
layer-backed, and has no `-layoutSubviews`. Views React Native creates itself
need all three, so they come from **`RCTPlatformView`**, a concrete `NSView`
subclass in the shim.

`RCTPlatformView` may appear in upstream source in exactly two positions:

```objc
@interface RCTView : RCTPlatformView          // superclass
[[RCTPlatformView alloc] initWithFrame:f]     // instantiation
```

**Never as a pointer type.** `UIView *` stays `UIView *`. That restriction is
the whole difference between this fork and `react-native-macos`: they made the
renamed type the *pointer* type too, which is why 538 files had to change.
Measured cost here: **21 files** — 8 superclass declarations, 13 instantiations.

`macos/ci/check-budget.sh` enforces the restriction.

On iOS, tvOS and visionOS, `macos/UIKitCompat/RCTPlatformViewCompat.h` defines
`RCTPlatformView` as an alias for `UIView`, so those builds gain one alias and
change in no other way. The prelude is force-included via `-include`, is guarded
on `__OBJC__` so C and C++ translation units are unaffected, and was verified to
compile against the iOS SDK.

### 4.6 Fabric host platform

Use `ReactCommon/react/renderer/components/view/platform/cxx` unchanged. Do not add a
`platform/macos` directory until we ship mouse or key events. `react-native-macos`'s macOS variant
exists only for those props.

---

## 5. Commit series

The fork is a **rebasable series of small commits**, ordered so that conflict-prone work sits last.

### 5.1 Ordering rule

**Commits that only add files in `macos/` come first. Commits that edit upstream files come last.**

New-file commits never conflict on rebase. Putting them first means a `git rebase` onto a new upstream
tag replays them instantly and stops only at the handful of commits that touch upstream source.

### 5.2 The series

| # | Commit | Touches upstream? | Upstream files | Status |
|---:|---|---|---:|---|
| 0 | `docs: add the macOS fork contract` | No — this file | 0 | **landed** |
| 1 | `feat(macos): add UIKit compatibility framework` | No — all new | 0 | **landed** |
| 2 | `feat(macos): add the budget linter and the syntax-check harness` | No — all new | 0 | **landed** |
| 3 | `build: declare macOS platform support [macOS]` | Yes | 2 | **landed** |
| 4 | `fix(macos): alias UIView to NSView and adopt RCTPlatformView [macOS]` | Yes | 21 | **landed** |
| 5 | `fix(macos): use RCTPlatformDisplayLink instead of CADisplayLink [macOS]` | Yes | 13 | **landed** |
| 6 | `feat(macos): complete the UIKit compatibility layer` | No — all `macos/` | 0 | **landed** |
| 7 | `test(macos): add shim behaviour tests and a recursion checker` | No — all `macos/` | 0 | **landed** |
| 8 | `build: make the CocoaPods graph install for :osx [macOS]` | Yes | 6 | **landed** |
| 9 | `fix(macos): close the gaps the shim cannot reach [macOS]` | Yes | 9 | **landed** |
| 10 | `feat(macos): add the AppKit host app` | No — all `macos/` | 0 | **landed** |
| 11 | `build(macos): publish to npm without renaming the package` | Yes | 1 | **landed** |
| 12 | `feat(macos): work with the macOS React Native ecosystem [macOS]` | Yes | 42 (+26 new) | **landed** |

Thirteen commits, 64 modified upstream files.

Commit 12 is what makes the fork usable rather than merely buildable:
`Platform.OS` reports `macos`, the macOS-only view props exist
(`tooltip`, `focusable`, mouse, key and drag handlers), `PlatformColor` resolves
AppKit's vocabulary, and Expo's BareExpo runs against it. It carries a
disproportionate share of the upstream files because the macOS-only props need
`validAttributes` entries and the colour work reaches into the Fabric colour
path, neither of which the shim can intercept.

The earlier count read 48 upstream files. The series diverged from the original plan
in one direction only: the planned per-pod commits (React-Core, React-Fabric,
coordinate semantics, touch synthesis, TextInput) collapsed into commits 8 and
9, because aliasing `UIView` to `NSView` removed most of what they were for.

The planned Hermes xcframework recomposition commit **was dropped**. It is not
needed: `hermes-engine.podspec` upstream already declares `:osx => "10.13"` and
already points `spec.osx.vendored_frameworks` at
`destroot/Library/Frameworks/macosx/hermesvm.framework`, which is already inside
every published release tarball.

### Progress

**The fork builds, links and runs.** `macos/HelloWorld` renders a Fabric tree
through AppKit on macOS 26.5 / Xcode 26.5, arm64:

```
pod install            85 pods, platform :osx, 14.0
xcodebuild             ** BUILD SUCCEEDED **, 0 undefined symbols
runtime                0 errors, 0 warnings
```

Getting from "compiles" to "renders" turned up five failures that no amount of
syntax checking could have found, because every one of them is silent:

1. **`bounds` means different things in UIKit and AppKit.** Fabric lays views
   out with `center` then `bounds` -- never `frame`, which is undefined once a
   layer transform is set. AppKit's `bounds` is a coordinate system and does
   not resize the frame, so the whole tree rendered correctly positioned and
   0x0. Fixed in `-[RCTPlatformView setBounds:]`; see commit 6.
2. **Feature flags were never set.** `RCTReactNativeFactory` installs
   `ReactNativeFeatureFlagsOverridesOSSStable` on iOS. Without it
   `enableBridgelessArchitecture` is false, and `HermesInstance` builds its
   runtime with the microtask queue disabled. React 19 schedules through
   microtasks, so the first render threw and nothing mounted.
3. **The surface started too early.** AppRegistry installs its global binding
   during bundle evaluation; the surface has to start in `hostDidStart:`.
4. **`Platform.js` resolved to itself.** It re-exports `./Platform` and expects
   a platform-suffixed sibling to win. Metro resolves one platform per request,
   so `macos` has to be handled as an extension chain.
5. **The app loaded a different project's bundle.** `localhost` resolves to ::1
   first, and another dev server held `*:8081`.

The syntax checker (`macos/scripts/syntax-check.sh`) remains the inner loop for
the files that are still excluded. Last full reading against `v0.87.1`:

```
252 upstream Objective-C sources
  6 excluded from the macOS build (macos/UIKitCompat/macos-excludes.txt)
246 checked
```

Progression of the syntax checker while the shim was being built: 59 -> 80 ->
125 -> 134 -> 141 -> 151 -> 171 -> 182 -> 195 -> 207 -> 215 -> 218 -> all.

Six changes were worth far more than their size:

- **`UIStatusBarManager`.** macOS has no status bar, so the type is nearly
  meaningless -- but `RCTUtils.h` names it and almost everything imports
  `RCTUtils.h`. Adding it moved 86 files at once.
- **Force-including the prelude.** Not every upstream file imports UIKit; some
  reach only for QuartzCore and still expect UIKit names in scope.
- **Aliasing `UIView` to `NSView`** (section 4.5). Fixes the view hierarchy for
  all ~322 `UIView *` sites at the cost of 21 files.
- **Running codegen.** `FBReactNativeSpec` and the generated Fabric descriptors
  do not exist in the repo, and ~90 sources could not be judged at all without
  them. A full monorepo install is not needed: the codegen package has seven
  dependencies and Meta publishes it prebuilt.
- **A `MobileCoreServices` shim directory.** Same trick as `UIKit` -- the
  framework does not exist on macOS, the name is free, and the declarations
  live in CoreServices.
- **The UIKit surface on an `NSObject` category.** UIKit declares accessibility
  as an informal protocol on `NSObject`; AppKit's is a formal protocol adopted
  by views. React Native stores accessibility elements as `NSObject *`.

### What is still excluded

Six paths are excluded from the macOS build rather than ported. None of them
blocks a rendering app; each is a native module with no AppKit equivalent, or a
dev-only tool.

```
Libraries/PushNotificationIOS/          no macOS equivalent
Libraries/Vibration/                    no macOS equivalent
React/CoreModules/RCTStatusBarManager   macOS has no status bar
React/CoreModules/RCTActionSheetManager NSAlert has a different shape
React/CoreModules/RCTDevMenu            dev-only, needs an NSMenu port
React/CoreModules/RCTPerfMonitor        dev-only, UIWindow-based
```

RedBox is deliberately *not* excluded: excluding half of it broke the other
half's header import.

Still unported, and each needs real behaviour rather than a name: `NSTextView`
and `NSTextField` text input, `NSScrollView` scroll semantics, and richer
`NSEvent` touch synthesis.

### Comparison with react-native-macos

Measured at the point where both render: their `0.81-stable` against this fork
at `v0.87.1`. "Modified" means an Apple source file (`.h .m .mm .swift
.podspec .rb`) carrying a `[macOS]` marker under `React/`, `Libraries/`,
`ReactApple/` or `scripts/`.

```
react-native-macos modified:  354 files
this fork has modified:        47 files   (13%)
  overlap:                     36
  they touched, we did not:   318
  we touched, they did not:    11
```

The 11 are not disagreements. Six are files that do not exist at 0.81
(`RCTRedBox2Controller`, `RCTFrameTimingsObserver`, the `RCTSwiftUI` pair) and
five are build plumbing where the two forks solve the same problem in different
places -- they carry macOS through a vendored podspec set, this fork extends
the upstream helpers.

Of the 318 avoided, classified by how much real change they carry once renames
and `[macOS]` tags are subtracted:

```
 26 files   purely cosmetic        <- structurally impossible for us to need
215 files   <=10 substantive lines
 57 files   11-50 lines
 36 files   >50 lines              <- the real work
```

Almost all of the avoided work is the first three rows: renames from `UIView`
to `RCTPlatformView`, `UIColor` to `RCTUIColor`, and `[macOS]` bookkeeping.
Aliasing `UIView` to `NSView` (section 4.5) deletes that category of change
outright.

The remaining 36 are where a shim stops helping, and this fork will have to pay
some of them too:

```
21 files  3,609 lines   core view / convert / scroll   partly paid
 8 files  1,958 lines   TextInput + Text               not started
 3 files    631 lines   touch + pointer                paid (3 files)
 4 files    794 lines   dev-only                       excluded
```

Landing point once text input and scrolling are real is **60-90 files against
their 354**. The floor is not renaming; it is flipped coordinates,
`NSScrollView` semantics, `NSEvent` touch synthesis and `NSTextView` text
input. A shim supplies a name, never a behaviour.

### Known blockers that the shim cannot absorb

Three cases were genuinely rung 4 and needed upstream edits. All three are
now handled; they are kept here because a future upstream bump will hit them
again.

1. **`CADisplayLink` (3 files).** QuartzCore declares
   `+displayLinkWithTarget:selector:` as `API_UNAVAILABLE(macos)`. A category
   cannot re-grant availability -- clang rejects the mismatched attribute -- so
   the call sites must be guarded. macOS 14 vends a display link from
   `NSScreen`; below that there is none and the timer fallback applies.
2. **`SCDynamicStoreCopyComputerName` (1 file).** Needs SystemConfiguration,
   which iOS does not link.
3. ~~The `UIView` / `UIScrollView` hierarchy.~~ **Resolved** — see §4.5.
4. **`NSEvent` has no `allTouches` (3 files).** `NSEvent` is not a `UIEvent`
   and cannot be given the property without lying about its type, so the call
   sites go through `RCTPlatformTouchesForEvent()`.
5. **`NSWindow` is not an `NSView` (3 files).** The same single-inheritance
   wall as section 4.5, but there is no alias that fixes it: the call sites
   reach through `.contentView`.

---

### 5.3 Tooling

`macos/scripts/init.js`, published as the `react-native-darwin-init` bin, adds a
`macos/` target to an existing app. It is the equivalent of
microsoft/react-native-macos-init and deliberately the same shape: it writes
files and prints the commands, rather than running the build.

Templates live in `macos/template/`. `publish.sh` vendors both into the package,
and `init.js` locates the package from its own path -- so it works whichever
name the app installed it under, which matters because the intended install is
an npm alias.

Verified end to end: packing a tarball, installing it into an empty project as
`react-native`, scaffolding, `pod install`, `xcodebuild`, and running the result
against its own Metro. `macos/template/README.md` is the consumer-facing
instructions.


## 6. Budgets and CI

### 6.1 The budget

```
MAX_UPSTREAM_FILES_MODIFIED = 135
MAX_UPSTREAM_LINES_REMOVED  = 200
MAX_COMMITS                 = 13
```

Only files that already exist upstream are budgeted. A file this fork *adds* --
`Platform.macos.js`, everything under `components/view/platform/macos/` -- has
no upstream counterpart, so it cannot conflict on a rebase, which is what this
number exists to bound. Added files are still counted and printed; they are
just not a failure condition. The combined figure was 88 when the split was
introduced: 63 modified, 25 added. The ceiling went from 90 combined to 70
modified at the same time, so the constraint stayed roughly as tight as it was.

Platform gates are counted as a third category, apart from both. Core branches
on `Platform.OS === 'ios'` in about forty places, and now that macOS reports
itself honestly it matches none of them -- so it silently takes the Android
path, or no path at all. Two of those were severe: every `<TextInput>` rendered
as empty space, and every WebSocket event was dropped, in both cases with
nothing logged.

Fixing one is the same single predicate every time, in a file the fork
otherwise never touches. Counting those as ordinary modifications makes the
linter say the shim is being under-used, which is exactly backwards -- there is
no shim answer to a JS platform check. The ceiling went 70 -> 80 to absorb them
before the category existed, and back to 75 once it did.

Raised again, 75 -> 135, for dropping the UIKit aliases. Declaring `UIView` in
a header on every pod's search path makes this fork a breaking change for any
library that declares it too -- `expo-modules-core` does -- and there is no way
to yield, because the preprocessor cannot ask whether an alias already exists.
The fix is that no installed header names a UIKit type, which means converting
58 of them. The fork gets bigger in order to stop being invasive, and that is
the right trade. See `macos/PLAN-drop-uikit-aliases.md`.

The category is **detected, not declared**: a file qualifies only if every line
its diff touches is part of such a predicate -- the test itself, a comment, or
a continuation of the same expression. One substantive line and it is an
ordinary modification again. That keeps it from becoming a place to hide
changes.

`MAX_COMMITS` was 11, became 12 when npm publishing landed, and 13 when the
fork was made to work with the wider macOS React Native ecosystem. The cap exists to
stop `wip` churn from accumulating, not to stop a new concern from getting its
own commit. Raise it when a genuinely separate concern needs a place; squash
when the history is just iteration.

For reference, `react-native-macos` at `0.81-stable` touches 603 files in `packages/react-native` and
removes 1,870 lines.

Current reading, with the app rendering on `v0.88.0-rc.3`:

```
Upstream files modified:  182 / 200
Files added by the fork:   27
Platform-gate one-liners:  13
Upstream lines removed:   449 / 600
Commits:                   16 / 16
```

`MAX_COMMITS` went 15 -> 16 for the 0.88 upgrade. Absorbing a new upstream tag is a
genuinely separate topic, and keeping it as one commit is what lets a reviewer see what
0.88 cost on its own rather than hunting for it folded into the alias migration. The diff
budgets above remain the real measure of fork size.

**Upstream files modified is the primary health metric of this fork.** Track it on every PR. If it
climbs, the shim is being under-used and rung 4 is being over-used.

The deletions limit started at 50 and was raised to 200 once real work landed.
It turned out to be the wrong proxy: nearly every deletion is half of a `-1/+1`
line replacement, such as `CADisplayLink *x` becoming `RCTPlatformDisplayLink *x`.
No upstream code is being removed, and writing around the count would mean
writing worse edits. The file count is what tracks rebase cost.

### 6.2 The linter

`macos/ci/check-budget.sh` runs on every PR and fails the build on any of these:

1. Upstream files modified exceeds `MAX_UPSTREAM_FILES_MODIFIED`.
2. Upstream lines removed exceeds `MAX_UPSTREAM_LINES_REMOVED`.
3. Commit count exceeds `MAX_COMMITS` (the contract commit does not count).
4. A changed hunk in an upstream file has no `[macOS]` marker in or adjacent to it.
5. A diff line in an upstream file introduces `RCTPlatformView`, `RCTUIView`, or `RCTUIColor`.
6. A file inside `macos/` contains a `[macOS]` marker.

Measured as:

```sh
git diff --numstat "$UPSTREAM_TAG"..HEAD -- . ':(exclude)macos/' ':(exclude)MACOS-FORK.md'
```

### 6.3 Reporting

Every PR description states:

```
Upstream files modified:  n / 75
Files added by the fork:  n
Platform-gate one-liners: n
Files added by the fork: n
Upstream lines removed:  n / 200
Commits:                 n / 13
```

---

## 7. Upgrading to a new upstream tag

1. Fetch the new tag.
2. `git rebase --onto upstream/<new-tag> upstream/<old-tag> macos/<old-tag>`
3. Commits 3 and 12 replay with no conflict: they only touch files this fork owns.
4. Resolve conflicts in the rest. Two carry most of the risk -- commit 5, which
   wires the pod graph and the host app, and commit 7, the alias migration --
   because they are the two that touch upstream headers in bulk. The `[macOS]`
   markers show exactly what each hunk was for.
5. Build for macOS. Run the budget linter.
6. Update `UPSTREAM_TAG` and `UPSTREAM_SHA` in §2.4.
7. Update the real line counts in §5.2.

Do not regenerate snapshots, lockfiles, or API files. We do not own them.

---

## 8. Deferred

Not in scope until the compile-and-render milestone lands. Each is additive.

| Deferred | Handled by |
|---|---|
| Mouse enter, leave, hover | Rung 2 — excluded |
| Key events, `validKeysDown` | Rung 2 — excluded |
| Cursor, tooltips, focus ring | Rung 2 — excluded |
| Drag and drop, context menus | Rung 2 — excluded |
| RedBox, DevMenu, PerfMonitor | Rung 2 — excluded, ~900 lines saved |
| ActionSheet, PushNotification, Vibration, StatusBar | Rung 2 — excluded, not applicable on macOS |
| `PlatformColor` for macOS | Rung 2 — excluded |
| Legacy bridge and Paper renderer | Not supported. New Architecture only. |

When a deferred item ships, it moves to §5.2 as its own commit, and the budget in §6.1 is raised
explicitly in the same PR.

---

## 9. Open questions

Resolve these before commit 1.

1. **Minimum macOS version.** `14.0`. Was `11.0`, matching the Hermes
   framework's `minos`, which turned out to be the wrong thing to match:
   React Native's own C++ and several community libraries use
   `std::filesystem`, which Apple marks unavailable before 10.15. The errors
   surface inside whichever third-party pod includes it first -- RNWorklets,
   in practice -- so they read as that library's bug rather than ours. 14.0
   also matches what Expo targets, so an app using both agrees.

   `updateOSDeploymentTarget` raises every pod target to it, the way upstream
   already does for iOS. A pod that declares no `:osx` platform otherwise
   inherits CocoaPods' default of 10.6.
2. **Architectures.** `arm64` only, or universal? Both prebuilt xcframeworks ship `arm64_x86_64`.
3. **Does upstream want any of this?** Three changes stand on their own merits and would shrink our
   budget if accepted: adding the macOS slice to the published Hermes xcframework; `:osx` in
   `min_supported_versions`; a `platform/macos` host-platform directory beside the existing `tvos` one.
4. **Distribution.** Patch series applied to an upstream tarball, or a published npm package?

---

## Appendix — Why the UIKit-name approach works

Verified on Xcode 26.5, macOS SDK 26.5.

There is no `UIKit.framework` in the macOS SDK:

```
$ ls $(xcrun --show-sdk-path --sdk macosx)/System/Library/Frameworks/ | grep -i uikit
(nothing)
```

So the names are free. This compiles and runs:

```objc
// macos/UIKitCompat/UIKit/UIKit.h  — reached via -I macos/UIKitCompat
#import <AppKit/AppKit.h>
@compatibility_alias UIColor NSColor;
@interface UIView : NSView
@property (nonatomic, copy, nullable) UIColor *backgroundColor;
- (void)layoutSubviews;
@end
```

```objc
// upstream source shape — UNMODIFIED
#import <UIKit/UIKit.h>

@interface UIView (React)
- (void)reactSetFrame:(CGRect)frame;
@end
@implementation UIView (React)
- (void)reactSetFrame:(CGRect)frame { self.frame = frame; }
@end

@interface RCTView : UIView @end
@implementation RCTView @end
```

```
$ clang -fobjc-arc -I macos/UIKitCompat -framework AppKit -o t t.m && ./t
ok flipped=1 bg=set frame=1,2 img=10 font=.AppleSystemUIFont
```

Four things this confirms:

1. A real class named `UIView`, subclassing `NSView`, compiles and runs on macOS.
2. `@compatibility_alias` works, including for category return types.
3. `#import <UIKit/UIKit.h>` resolves through `-I`. **The 165 upstream files that import UIKit need
   zero edits.**
4. `@interface UIView (React)` categories attach correctly. React Native uses these heavily.

**What it does not solve.** Measured against `react-native-macos`: reusing UIKit names recovers about
2,232 of 17,416 changed lines, and fully clears only 32 of 538 files. The remaining ~15,000 lines are
real AppKit behaviour — touch synthesis from `NSEvent`, `NSTextView`-based text input, flipped
coordinates, responder chain. The rules in this file **defer and contain** that work. They do not
remove it.

What the approach does deliver is shallowness: it takes 371 of 538 files down to 10 lines of change or
fewer. That is where rebase cost actually lives.
