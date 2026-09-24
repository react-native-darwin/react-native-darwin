# What is missing, and in what order

Everything below was measured on 2026-09-27 against `0.87.1-rc.12`, by running
the code rather than by reading it. Where something is listed as unverified, it
means exactly that: not that it works.

The ordering is by what stops an ordinary app from working, not by how close it
gets us to react-native-macos feature-for-feature. Those are different lists,
and the first one matters more.

## P0a — scrolling crashes the app

Scrolling a `ScrollView` or a `FlatList` with the trackpad kills the process.
Reproducible, immediate, and **silent**: no exception, no log line, no crash
report. Both render correctly and show scrollbars right up until the first
scroll event.

Lists are most of what an app is, so this outranks everything below it.

**Where to start.** The mouse-to-touch translation added for presses handles
`mouseDown`/`mouseDragged`/`mouseUp` but nothing routes `scrollWheel:`. The
crash is likely in the scroll event path rather than in the translation, since
no touch is involved -- but that is a guess, and the first job is a stack, not
a fix. Run under a debugger rather than from a terminal; the process dies
without unwinding.

## P0b — `<Button>` and `TouchableOpacity` do not work

`NativeAnimatedModule` never reaches JS. Every `Animated` value with
`useNativeDriver: true` throws `Invariant Violation: Native animated module is
not available`, and that takes down whatever rendered it.

The blast radius is much wider than `Animated`:

  - `TouchableOpacity` and `TouchableHighlight` animate opacity natively.
  - `<Button>` wraps `TouchableOpacity`, so a single `<Button>` blanks the app.
  - **LogBox** animates too. So *any* warning is fatal: the warning renders
    LogBox, LogBox throws, and the screen goes white. Several blank screens
    chased during this work were this, not the thing being tested.

`Pressable` is unaffected -- it does not use `Animated` -- which is why presses
looked fine until a `<Button>` appeared.

**Partly addressed, still broken.** The host used to ask only
`RCTCoreModulesClassProvider`, so the class was never even found;
`RCTNativeAnimatedModule` is vended by `RCTAnimationClassProvider` in
React-RCTAnimation. The host now asks every pod's provider in turn, which fixed
`<Image>` and networking for the same reason -- and the animated class does now
resolve, confirmed by logging `NativeAnimatedModule -> RCTNativeAnimatedModule`.

JS still reports it missing. So the class is found and the *instance* never
reaches JS. Declining the legacy name to force the `NativeAnimatedTurboModule`
path does not help: JS never asks for that name either. The next step is the
instantiation path -- `RCTAppSetupDefaultModuleFromClass` and what
`RCTNativeAnimatedModule` needs from a surface presenter under bridgeless --
not the lookup.

**Verify.** A `<Button>` taps; `Animated` with `useNativeDriver: true` runs to
completion; a `console.warn` renders LogBox instead of blanking the app.

## P1 — the component surface nobody has exercised

These were never reached: the probe crashed on `<Button>` before rendering
them. Unknown, not broken.

Measured since:

| Component | State |
|---|---|
| `Switch` | **works** -- toggles, reports `onValueChange` |
| `ActivityIndicator` | renders; whether it animates is unverified |
| `ScrollView`, `FlatList` | render with scrollbars, then **crash on scroll** (P0a) |
| `Modal` | **does not open**. No error; the press registers and nothing appears |
| `Slider`, `Picker` | still unverified |
| Third-party native module | still unverified |

`Modal` is its own gap: RN mounts it through `RCTModalHostView`, which on iOS
presents a `UIViewController` modally. There is no such thing on AppKit -- it
needs either a child `NSWindow` or an overlay view in the same window, and
which one it should be is a design decision, not a port.

The third-party module check still matters most of the rest. The dependency
provider landed in rc.12 is what makes autolinked modules reachable at all, and
no actual module has been through it.

The last matters most. The dependency provider landed in rc.12 is what makes
autolinked modules reachable at all, and no actual module has been through it
yet. `react-native-safe-area-context` is the obvious first one: BareExpo
already links it.

## P2 — parity with react-native-macos

Real gaps, none of which stop an app working.

  - **TextInput, nine props.** `submitKeyEvents`, `onPaste`, `pastedTypes`,
    `grammarCheck`, `clearTextOnSubmit`, `hideVerticalScrollIndicator`,
    `onAutoCorrectChange`, `onSpellCheckChange`, `onGrammarCheckChange`.
    `onPaste` and `pastedTypes` can reuse the `DataTransfer` plumbing already
    written for drag and drop.
  - **`Alert.promptMacOS`.** An NSAlert with accessory text fields.
  - **`AccessibilityInfo.isHighContrastEnabled`.**
  - **`Text`**: react-native-macos carries a workaround for a background colour
    bleeding past the frame without a border radius. Reproduce it here before
    porting it -- it may not apply.

Explicitly *not* gaps, though they look like ones: ScrollView's `inverted` and
`onPreferredScrollerStyleDidChange` exist only in the old architecture. This
fork is Fabric-only, and react-native-macos has no native reader for either
under Fabric.

## P3 — release and upkeep

  - Promote a stable `0.87.1` off `next` once P0a and P0b are clear. Not
    before: an app that crashes when scrolled is not a release.
  - Upstream the three Expo-side patches that `fix-macos-env.sh` re-applies.
  - Put a probe app in CI. Every gap on this page was found by running one and
    looking at the window; none would have been caught by the build passing.

## Interop — Expo needs a one-line change

`expo-modules-core` declares the UIKit names itself for macOS, in
`ios/Platform/Platform.h`:

```objc
@compatibility_alias UIView NSView;
@compatibility_alias UIResponder NSResponder;
...
```

So does this fork, and `@compatibility_alias` is a hard error on redefinition
even when both declarations name the same class. The build fails with
`conflicting types for alias 'UIView'` while compiling the ExpoModulesCore
clang module, and takes whatever was being built with it down too -- usually
RNReanimated, with an unhelpful `Command Libtool failed`.

Nothing can be done from this side: there is no way to ask the preprocessor
whether a `@compatibility_alias` already exists. Expo has to defer when a real
UIKit header set is present, which is correct for it independently of this
fork:

```objc
#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
@compatibility_alias UIView NSView;
...
#endif
```

Until that lands upstream, an app using both needs the patch applied to its own
`node_modules/expo-modules-core` -- `patch-package` is the usual way.

That is a workaround, not the answer. Requiring a patch to somebody else's
package is not a shipping story, and the real fix is for this fork to stop
declaring the names at all: see `macos/PLAN-drop-uikit-aliases.md`. Treat that
as ranking above everything else here except the scroll crash -- a fork that
breaks the libraries it is meant to work with has a correctness problem, not
just a missing feature.
