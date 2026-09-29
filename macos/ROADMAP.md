# What works, what does not, and what is next

Everything below was measured on 2026-09-29 against `0.87.1`, by running the
code rather than by reading it — driving a real app with synthetic mouse, wheel
and key events and looking at the window. Where something is listed as
unverified it means exactly that: not that it works.

Every gap ever recorded on this page was found by running an app. None would
have been caught by the build passing.

## What works

| Area | State |
|---|---|
| `View`, `Text`, `Image`, `PlatformColor` | render, including remote images |
| `TextInput` | both kinds, all nine macOS props, paste, scrolling, focus/blur |
| `ScrollView`, `FlatList`, `SectionList` | scroll with the wheel, `onScroll` fires |
| `Modal` | presents as a sheet, `onShow` fires |
| `Alert`, `Alert.promptMacOS` | present as an `NSAlert` sheet |
| `Button`, `Pressable`, all four Touchables | press and report |
| `Animated` with `useNativeDriver` | runs |
| `Switch` | toggles, reports `onValueChange` |
| `ActivityIndicator` | renders **and animates** |
| `AccessibilityInfo.isHighContrastEnabled` | reads `NSWorkspace` |
| Key events, mouse events, drag and drop | deliver |
| Third-party native modules | autolink, build and **run** |

`react-native-safe-area-context` is the third-party case, verified end to end
and unmodified: it autolinks, builds, links, and `useSafeAreaInsets()` returns
real values in a running app.

`Slider` and `Picker` are not on this list because they are not part of React
Native any more — both were extracted to community packages years before 0.87.
Whether `@react-native-community/slider` works is the third-party question, not
a separate one.

## What is left

Nothing on this list stops an ordinary app from working.

### A conflicting sync still needs a person

`.github/workflows/macos-sync.yml` runs weekly: it finds the newest upstream
release, rebases the macOS commits onto it, runs the budget and the shim tests,
and opens a pull request. What it cannot do is decide what a macOS change was
*for* when the rebase conflicts, which is the only case that matters — so it
reports which commit stopped and which paths conflicted, and gets out of the
way. The platform marker on every upstream hunk exists to make that decision
possible. A red sync run is the signal to look, not a failure of the workflow.

### `Text` background colour

react-native-macos carries a workaround for a background colour bleeding past
the frame when there is no border radius. **Reproduce it here before porting
it** — the drawing path has changed enough that it may not apply.

### Driving a window in CI

The build passing has never once predicted that the app works. Every P0 on this
page was found by driving a window with real input events.

The tool for that is now committed as `macos/tests/uiprobe/uiprobe.m` — click,
scroll, type and key-with-modifiers, posted through `CGEventPost`, which needs
no Accessibility permission and so runs unattended. `macos/tests/run.sh`
compiles it on every run.

What is still missing is the other half: a CI job that launches HelloWorld,
drives it, and asserts on what the app logged. Compiling the tool keeps it from
rotting; it does not yet catch anything.

### Explicitly not gaps

ScrollView's `inverted` and `onPreferredScrollerStyleDidChange` exist only in
the old architecture. This fork is Fabric-only, and react-native-macos has no
native reader for either under Fabric.

## What was fixed, and what it taught

Kept because the reasoning is worth more than the changelog: every one of these
was a wrong assumption, not a missing line.

**Scrolling killed the process.** An unconstrained `NSClipView` —
`constrainBoundsRect:` returning the proposal untouched — lets AppKit's
momentum scroller advance the bounds origin with no limit until
`_NSViewValidateGeometry` traps and the process dies without unwinding. The
constraint is now lifted only for a programmatic `setContentOffset:`, which
UIKit honours past the content bounds and AppKit otherwise clamps.

**`<Button>` blanked the app.** `shouldUseTurboAnimatedModule()` gated on
`Platform.OS === 'ios'`, so macOS asked for the legacy `NativeAnimatedModule`
name while the native side registers `NativeAnimatedTurboModule`. Everything
touching `Animated` threw — including LogBox, which made *any* warning fatal
and sent several debugging sessions chasing the wrong thing.

**`Modal` never opened**, for three reasons at once: AppKit does not link a
view to its superview through `-nextResponder`, so `-reactViewController`
walked an empty chain; the template assigned the surface straight to
`contentView`, so there was no `NSViewController` to find; and the presented
controller's view had an empty frame with `-viewDidLayout` never bridged to
`-viewDidLayoutSubviews`.

**`Alert` did nothing at all**, also for three: the JS was gated to iOS; the
controller built a throwaway `UIWindow` to present into, which on AppKit puts
up an empty window; and the shim's factory allocated its own class rather than
`[self alloc]`, so React Native's subclass was never instantiated.

**Multiline `TextInput` could not scroll**, because `UITextView` *is* a
`UIScrollView` on iOS and the compatibility layer backs it with a bare
`NSTextView`. It is now the document view of a real `NSScrollView`.

**The first keystroke in a multiline field was swallowed.** An iOS workaround
in `textInputDidChangeSelection` treats a selection change as a text change;
on AppKit, clicking into a field moves the selection before any edit, so it
fired a change carrying the pre-edit text and armed the flag that then ate the
first real keystroke.

**The app had no menu.** On a Mac the menu *is* the keyboard shortcuts: Cmd+V
is a key equivalent AppKit matches against the main menu and turns into
`-paste:`. Without one, nothing built from the template could cut, copy, paste,
undo or select all from the keyboard.

**Autolinking never worked.** `@react-native-community/cli` has no macOS
platform plugin, so it files every package under `ios`, and the per-package
lookup had no fallback. Every third-party native module was silently skipped.

**The compatibility layer reached no pod.** Ownership was decided from the
podspec's path, but CocoaPods copies every local podspec into
`Pods/Local Podspecs` and points `defined_in_file` at the copy — so the answer
was "none of them". It now comes from the pod's source root.

**Third-party Fabric components were never registered.** The template built a
dependency provider, which covers turbo modules, but never handed a components
provider to `RCTComponentViewFactory`. A library's views were linked into the
binary and unknown to JavaScript.

## The alias migration

This used to be the largest item on the page, under a heading saying Expo
needed a one-line patch. It does not any more, and that section has been
deleted rather than amended, because it described the opposite of the current
arrangement.

`expo-modules-core`, `react-native-reanimated`, `react-native-safe-area-context`
and `react-native-screens` all declare the UIKit names themselves on macOS, for
the same reason this fork used to and just as legitimately. Two
`@compatibility_alias` declarations of the same name are a hard error even when
both name the same class, and the preprocessor cannot be asked whether one
already exists — so for a while an app using both needed a patch applied to
somebody else's package.

That is fixed. The compatibility layer is split along a line that is not
obvious but is exact:

- `@compatibility_alias`, a class `@interface`, a `@protocol` and an `NS_ENUM`
  are errors on *re*declaration. **Private** to this fork's own pods.
- A `typedef`, a `#define`, an inline function and a category can all be
  declared twice as long as they match. **Public**, and every pod gets them.

### The half that was missing

Removing the aliases was only half the contract, and the first real Expo build
found the other half. `expo-modules-core` declares seven names itself — `UIView`,
`UIColor`, `UIImage`, `UIWindow`, `UIResponder`, `UIImageView`,
`UIHostingController` — and imports `<React/RCTUIKit.h>` for everything else it
uses. react-native-macos declares 44 more there, including `UIViewController`.
This fork declared none, so `EXReactDelegateWrapper.h` failed on
`- (UIViewController *)createRootViewController` with `expected a type`.

So the partition is not "React Native declares nothing". It is that the
ecosystem already agreed a split, and the two sets are disjoint: libraries own
the seven, React Native owns the other 44. `React/RCTUIKit.h` now declares that
44 — suppressed inside this fork's own pods, which already have the full shim —
and `check-budget.sh` rule 8b fails the build if any of the seven is ever
claimed there.

The acceptance test was rewritten at the same time, because it had been giving
false confidence: it declared `UIFont`, `UIViewController` and `UIBezierPath`
itself, which no real library does, so it passed while the real library did
not build. A stand-in more self-sufficient than the thing it stands in for
proves nothing.

Installed headers use the neutral vocabulary — `RCTPlatformView`, `RCTUIColor`
— which is what react-native-macos uses too, so third-party code written
against that fork compiles here unchanged. `check-budget.sh` rule 8 fails the
build if the line is crossed, and `macos/tests/` compiles a stand-in for
`expo-modules-core`'s `Platform.h` on every run to prove it.

See `macos/PLAN-drop-uikit-aliases.md` for how it was done, and
`macos/PLAN-upstream.md` for which of these changes belong upstream instead —
the rename is 60% of this fork's modified files, and it exists only because
React Native's public headers spell `UIView` directly.

## Traps worth not rediscovering

**Install the tarball, not a `file:` path.** npm makes a `file:` dependency a
symlink, Node resolves `__dirname` through it, and the Metro redirect takes its
target from the install directory's *name* — so it silently becomes a no-op,
the bundle gets upstream React Native, which has no macOS view configs, and
every third-party component dies with `Cannot read property 'bubblingEventTypes'
of undefined`. The symptom names neither the cause nor the fix.
`macos/scripts/publish.sh` without `--publish` builds exactly the tarball to
install.

**Never register a UIKit name with the Objective-C runtime.** Apple frameworks
probe `NSClassFromString(@"UITextField")` to decide a process is Catalyst;
macOS AutoFill then `dlopen`s a `UIKit.framework` that does not exist and takes
the process down — from nothing more than clicking into a text field.

**Check which Metro you are talking to.** More than one can be running; a
bundle served by the wrong one looks like a code change that did not take.
