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

**Non-goal.** Feature parity with `microsoft/react-native-macos`. That fork changes 603 files and
about 23,000 lines in `packages/react-native`. We target fewer than 90 upstream files.

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
      UIView.h / .m
      UIScrollView.h / .m
      UIColor.h               Aliases and categories.
      ...
  Host/                       NSApplication delegate, NSWindow, root view.
  scripts/                    Hermes xcframework recomposition, build helpers.
  ci/                         Budget linter.
MACOS-FORK.md                 This file.
```

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
UPSTREAM_TAG = v0.87.1
UPSTREAM_SHA = a59eff64fa
```

Verified present at this tag:
- Hermes tarball ships `destroot/Library/Frameworks/macosx/hermesvm.framework`, universal x86_64+arm64.
- `ReactNativeDependencies.xcframework` ships a `macos-arm64_x86_64` slice.
- 2 Swift files in Apple-facing directories, so no Swift module-map problem.
- All podspecs share one `min_supported_versions` helper.

### 2.5 Branch model

```
upstream/v0.87.1  ──  macos/v0.87.1   (our commits, rebased — never merged)
```

**Rebase onto new upstream tags. Never merge.** Merging produces the snapshot-regeneration tax
described in §2.2. Rebasing keeps the commit series readable and keeps the budget measurable.

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

| # | Commit | Touches upstream? | Budget (files / lines) | Status |
|---:|---|---|---|---|
| 0 | `docs: add the macOS fork contract` | No — this file | 0 / ~440 | **landed** |
| 1 | `feat(macos): add UIKit compatibility framework` | No — all new | 0 / ~2,000 | **landed, 0 / 3,001** |
| 2 | `feat(macos): add the budget linter and the syntax-check harness` | No — all new | 0 / ~400 | **landed, 0 / 447** |
| 3 | `build: declare macOS platform support [macOS]` | Yes | 3 / ~150 | **landed, 2 / 17** |
| 4 | `fix(macos): alias UIView to NSView and adopt RCTPlatformView [macOS]` | Yes | 21 / ~45 | **landed, 21 / 42** |
| 4a | `feat(macos): add AppKit host layer` | No — all new | 0 / ~400 | not started |
| 5 | `build: wire UIKit compat and exclusions into macOS builds [macOS]` | Yes | 6 / ~150 | not started |
| 6 | `fix(macos): compile React-Core for macosx [macOS]` | Yes | ~25 / ~1,200 | in progress |
| 7 | `fix(macos): compile React-Fabric for macosx [macOS]` | Yes | ~15 / ~800 | not started |
| 8 | `fix(macos): correct coordinate and layer semantics [macOS]` | Yes | ~12 / ~600 | not started |
| 9 | `feat(macos): synthesize touch events from NSEvent [macOS]` | Yes | ~8 / ~600 | not started |
| 10 | `feat(macos): TextInput on NSTextField and NSTextView [macOS]` | Yes | ~15 / ~2,000 | not started |

The planned Hermes xcframework recomposition commit **was dropped**. It is not
needed: `hermes-engine.podspec` upstream already declares `:osx => "10.13"` and
already points `spec.osx.vendored_frameworks` at
`destroot/Library/Frameworks/macosx/hermesvm.framework`, which is already inside
every published release tarball.

### Progress

`macos/scripts/syntax-check.sh`, run against `v0.87.1`, with codegen output
present (`macos/scripts/generate-codegen.sh`):

```
252 upstream Objective-C sources
 17 excluded from the macOS build (macos/UIKitCompat/macos-excludes.txt)
235 checked
218 parse cleanly against the macOS SDK
 17 fail
      1 blocked by the harness (a Swift module it cannot build)
     16 blocked by a genuine macOS issue
```

Of the 234 files the harness can judge, **218 (93%) compile**.

Progression: 59 -> 80 -> 125 -> 134 -> 141 -> 151 -> 171 -> 182 -> 195 -> 207
-> 215 -> 218.

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

### The remaining 16

Every one needs an upstream edit; none can be reached from a header.

| Count | Blocker |
|---:|---|
| 2 | Touch and pointer handlers: `NSTouchTypeMask` and `NSGestureRecognizerState` conflict irreconcilably with UIKit's types of the same name (commit 9) |
| 5 | Text input: `NSTextView` and `NSTextField` geometry and delegate shapes (commit 10) |
| 2 | `UIWindow` is a `UIView` on iOS and `NSWindow` is not an `NSView` -- the same single-inheritance wall as section 4.5, in `RCTDeviceInfo` and `RCTInputAccessoryComponentView` |
| 1 | `SCDynamicStoreCopyComputerName` needs SystemConfiguration, which iOS does not link |
| 6 | Assorted: edit-menu interactions, presentation controllers, scroll-view touch delays |

### Comparison with react-native-macos

Their modified Apple source files versus ours, at the same point in the work:

```
react-native-macos modified:  353 files
this fork has modified:        21 files
  overlap:                      19
  they touched, we did not:    334
  we touched, they did not:      2
```

Of the 334 we have avoided, classified by how much real change they carry once
renames and `[macOS]` tags are subtracted:

```
 26 files   purely cosmetic        <- structurally impossible for us to need
215 files   <=10 substantive lines
 57 files   11-50 lines
 36 files   >50 lines              <- the real work
```

and those 36:

```
21 files  3,609 lines   core view / convert / scroll   unavoidable
 8 files  1,958 lines   TextInput + Text               commit 10
 3 files    631 lines   touch + pointer                commit 9
 4 files    794 lines   dev-only                       excluded
```

Realistic landing point is **60-90 files against their 353**. The floor is not
renaming; it is flipped coordinates, `NSScrollView` semantics, `NSEvent` touch
synthesis and `NSTextView` text input. A shim supplies a name, never a
behaviour.

### Known blockers that the shim cannot absorb

Three cases are genuinely rung 4 and will need upstream edits:

1. **`CADisplayLink` (3 files).** QuartzCore declares
   `+displayLinkWithTarget:selector:` as `API_UNAVAILABLE(macos)`. A category
   cannot re-grant availability -- clang rejects the mismatched attribute -- so
   the call sites must be guarded. macOS 14 vends a display link from
   `NSScreen`; below that there is none and the timer fallback applies.
2. **`SCDynamicStoreCopyComputerName` (1 file).** Needs SystemConfiguration,
   which iOS does not link.
3. ~~The `UIView` / `UIScrollView` hierarchy.~~ **Resolved** — see §4.5.

---

## 6. Budgets and CI

### 6.1 The budget

```
MAX_UPSTREAM_FILES_TOUCHED = 90
MAX_UPSTREAM_LINES_REMOVED = 200
MAX_COMMITS                = 11
```

For reference, `react-native-macos` at `0.81-stable` touches 603 files in `packages/react-native` and
removes 1,870 lines.

**Upstream files touched is the primary health metric of this fork.** Track it on every PR. If it
climbs, the shim is being under-used and rung 4 is being over-used.

The deletions limit started at 50 and was raised to 200 once real work landed.
It turned out to be the wrong proxy: nearly every deletion is half of a `-1/+1`
line replacement, such as `CADisplayLink *x` becoming `RCTPlatformDisplayLink *x`.
No upstream code is being removed, and writing around the count would mean
writing worse edits. The file count is what tracks rebase cost.

### 6.2 The linter

`macos/ci/check-budget.sh` runs on every PR and fails the build on any of these:

1. Upstream files touched exceeds `MAX_UPSTREAM_FILES_TOUCHED`.
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
Upstream files touched:  n / 90
Upstream lines removed:  n / 200
Commits:                 n / 11
```

---

## 7. Upgrading to a new upstream tag

1. Fetch the new tag.
2. `git rebase --onto upstream/<new-tag> upstream/<old-tag> macos/<old-tag>`
3. Commits 1 to 3 replay with no conflict. They only add files.
4. Resolve conflicts in commits 4 to 10. The `[macOS]` markers show exactly what each hunk was for.
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

1. **Minimum macOS version.** Proposed `11.0`, matching the Hermes framework's `minos`.
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
