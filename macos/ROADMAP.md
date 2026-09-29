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

## P0d - multiline TextInput does not scroll -- FIXED

Found while adding `hideVerticalScrollIndicator`, which turned out to be a
no-op: the text view's `enclosingScrollView` was nil.

On iOS `UITextView` *is* a `UIScrollView`. The compatibility layer backs it
with a bare `NSTextView`, which is neither in a scroll view nor one itself, so
`scrollEnabled`, `contentOffset` and `contentSize` all degraded to nothing and
a multiline field taller than its frame simply clipped.

`RCTTextInputComponentView` now hosts a multiline field in a real
`NSScrollView` with the text view as its document view, and the text view is
vertically resizable so it grows with its text. `onScroll` is driven from the
clip view's bounds-change notification, which is how AppKit reports scrolling.

Verified: 25 lines in a 120pt box, wheel events move the text and `onScroll`
fires with a rising offset; `hideVerticalScrollIndicator` removes the scroller.

## P0e - the first keystroke in a multiline field was swallowed -- FIXED

Found while regression-testing P0d, and not caused by it -- it reproduced
before that change too.

`textInputDidChangeSelection` carries an iOS workaround: for multiline, a
selection change whose text differs from the last state is treated as a text
change, and `_ignoreNextTextInputCall` is armed. On AppKit, clicking into a
field moves the selection while that last state is still nil, so it fired a
change carrying the *pre-edit* text -- and the armed flag then swallowed the
first real keystroke. `onChangeText` reported `""`, then `"pq"`, then `"pqr"`.

The workaround is unnecessary here: `NSTextView` funnels every edit, including
paste, drops and undo, through `-didChangeText`, which the compatibility layer
bridges. It is now gated out on macOS.

## P1 — the component surface nobody has exercised

These were never reached: the probe crashed on `<Button>` before rendering
them. Unknown, not broken.

Measured since:

| Component | State |
|---|---|
| `Switch` | **works** -- toggles, reports `onValueChange` |
| `ActivityIndicator` | renders; whether it animates is unverified |
| `ScrollView`, `FlatList` | **work** -- scroll without crashing since P0a |
| `Modal` | **works** -- presents as a sheet, `onShow` fires |
| `Alert` | **works** -- presents as an `NSAlert` sheet |
| `TextInput` | **works** -- both kinds, all nine macOS props, paste, scrolling |
| Third-party native module | **works** -- safe-area-context autolinks, builds and runs |

`Slider` and `Picker` used to be listed here. They are not part of React
Native any more -- both were extracted to community packages years before
0.87 -- so there is nothing in this fork to verify. Whether
`@react-native-community/slider` works is the third-party question below,
not a separate one.

## P1a - third-party native modules

Tested by scaffolding an app with `react-native-darwin-init` and adding
`react-native-safe-area-context`, which declares macOS support. Three real
bugs fell out, all fixed:

  - **Autolinking never worked at all.** `@react-native-community/cli` has no
    macOS platform plugin, so it files every package under `ios` -- and the
    per-package lookup had no fallback, so every native module was silently
    skipped. It is the same podspec either way, and the platform check below
    it rejects the ones that genuinely do not support macOS.

  - **The compatibility layer reached nothing.** Which pods are ours was
    decided by where their podspec sits, but CocoaPods copies every local
    podspec into `Pods/Local Podspecs` and points `defined_in_file` at the
    copy -- so the answer was "none of them". Ownership now comes from the
    pod's source root. This was broken for HelloWorld too and only went
    unnoticed because its Pods project still carried settings from before.

  - **A UIKit function leaked through a public header.** `RCTLayout.h` called
    `UIEdgeInsetsEqualToEdgeInsets`. The audit that drove the alias migration
    looked for *types*, and missed that not every UIKit name is one.

That last one turned up something better than a fix. Only
`@compatibility_alias` and `@protocol` cannot be declared twice; a typedef, a
macro and an inline function can, as long as the declarations match. So the
UIKit geometry vocabulary -- `UIEdgeInsets` and its helpers -- is now in the
*public* half, where a library that declares the same names is not a conflict.
The private half keeps only what genuinely cannot repeat.

`react-native-safe-area-context` now **builds and links** unmodified, and the
native component registry reports both of its Fabric components as known.

Two more things were needed to get there:

  - **The UIKit view surface went public.** The library calls `layoutSubviews`
    on an `RCTView`, as code written against react-native-macos does. Those
    are category methods on `NSView`, and a category is not an alias -- a
    second library declaring the same selectors is not an error -- so the
    whole category moved to the public half under neutral signatures. This is
    the line between "no library has to change" and "the shim stays small",
    and it is drawn deliberately at: anything that can be declared twice is
    public, anything that cannot is private.

  - **Third-party Fabric components were never registered.** The app template
    built a dependency provider, which covers turbo modules, but never handed
    a components provider to `RCTComponentViewFactory`. A library's views were
    linked into the binary and unknown to JavaScript.

### Verified end to end

`react-native-safe-area-context` autolinks, builds, links and **runs**
unmodified: `useSafeAreaInsets()` returns real values and the app renders.

Getting there took one more correction, to the test rather than the fork. The
package has to be installed the way a user installs it -- a real npm tarball
under the `react-native-macos` alias -- because the Metro redirect takes its
target from the install directory's name. A `file:` install is a symlink, and
Node resolves `__dirname` through it, so the name comes back as
`react-native` and the redirect becomes a no-op: the bundle then contains
upstream React Native, which has no macOS view configs, and every third-party
component fails with `Cannot read property 'bubblingEventTypes' of undefined`.

That is worth knowing beyond this test. Anyone pointing an app at a local
checkout of this fork will hit it, and the symptom names neither the cause nor
the fix. `macos/scripts/publish.sh` without `--publish` builds exactly the
tarball to install.

## P2 — parity with react-native-macos

Real gaps, none of which stop an app working.

  - **TextInput, nine props.** `submitKeyEvents` -- done, `onPaste` -- done, `pastedTypes` -- done,
    `grammarCheck`, `clearTextOnSubmit`, `hideVerticalScrollIndicator`,
    `onAutoCorrectChange` -- done, `onSpellCheckChange` -- done, `onGrammarCheckChange` -- done.
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
