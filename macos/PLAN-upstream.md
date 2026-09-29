# What to upstream, and in what order

The GitHub compare against `v0.87.1` shows **319 changed files, 19,836
additions**. That number is mostly this fork's own new files — the
compatibility layer, the template, the host app and its generated Xcode
project. They are not a maintenance cost: they never conflict, because nothing
upstream touches them.

The number that matters is the one the budget linter tracks: **195 modified
upstream files, 3,401 changed lines.** Every one of those is a hunk somebody
has to re-resolve at each upstream release. This document asks which of them
would disappear if upstream accepted a change, and ranks the asks by how much
they remove per unit of upstream disruption.

## What the 195 files are made of

Measured, not estimated:

| Category | Files | Lines |
|---|---:|---:|
| Vocabulary rename — `UIView *` to `RCTPlatformView *` in installed headers | **117** | 826 |
| Native `TARGET_OS_OSX` gates | 22 | 1,394 |
| `Platform.OS === 'ios'` gates in JavaScript | 23 | 285 |
| Build, podspecs and CocoaPods scripts | 10 | 203 |
| Everything else | 23 | 693 |

Two things stand out. The rename is **60% of the files but only 24% of the
lines** — it is broad and shallow, which is exactly the shape that makes
rebases expensive. And the native gates are the reverse: few files, many lines,
genuinely macOS-specific behaviour that nobody else wants.

## The asks, ranked by leverage

### 1. A platform-neutral view type in installed headers

**Removes 117 files and 826 lines — 60% of the fork's modified files.**

React Native's public headers spell `UIView *`, `UIColor *`, `UIImage *`
directly. On a platform with no UIKit those names have to come from somewhere,
and whoever provides them claims a global name that no second library can
claim — which is why this fork renamed every installed header to a neutral
vocabulary in the first place.

The ask: upstream declares the vocabulary itself and uses it in installed
headers. On iOS it is a `typedef`/`@compatibility_alias` back to the UIKit type
— a no-op, no behaviour change, no ABI change.

**Independent argument.** This is not a favour to one fork. React Native
documents out-of-tree platforms as a supported concept, and every one of them
pays this same tax: react-native-macos renames ~500 files, react-native-windows
carries its own equivalent. A neutral spelling in the public API is the
single change that makes an out-of-tree platform cheap for everyone, and it
costs iOS nothing.

**Honest about the size.** This is not a small change for upstream: it touches
~98 headers. It is mechanical and scriptable, and it is the only item on this
page that halves our diff. If exactly one thing can be upstreamed, it is this.

### 2. One predicate for "an Apple platform"

**Removes 23 files and 285 lines.**

Every one of these is the same edit:

```js
-if (Platform.OS === 'ios') {
+if (Platform.OS === 'ios' || Platform.OS === 'macos') {
```

The pattern appears in `Alert`, `Button`, `ScrollView`, `TextInput`,
`AppState`, `Keyboard`, `shouldUseTurboAnimatedModule` and a dozen more. Two of
them were severe here: one made every `<TextInput>` render as empty space, and
one made every `Animated` value throw, which took down LogBox and so turned any
warning into a blank screen.

The ask: a capability predicate — `Platform.isApplePlatform`, or whatever
upstream prefers — and use it at these sites.

**Independent argument.** `Platform.OS === 'ios'` is already the wrong test
upstream. It is asking "is this UIKit-shaped?" and answering with a product
name, which is why tvOS and visionOS have each had to be special-cased at these
same sites over time. A predicate says what the code means.

### 3. Podspecs declare `:osx`

**Removes ~10 files and 203 lines.**

Several core podspecs declare only `:ios`, `:tvos` and `:visionos`, so the pod
graph will not resolve for macOS at all. Adding the platform is a line each.

**Independent argument.** The same list already grew to admit tvOS and
visionOS. This is the established pattern, not a new one.

### 4. Autolinking should fall back to the `ios` entry

**Removes 1 file and ~8 lines — and is worth more than its size.**

`@react-native-community/cli` has no macOS platform plugin, so it files every
package under `ios`. The per-package lookup in `autolinking.rb` has no
fallback, so on a macOS target **every third-party native module is silently
skipped** — no error, nothing linked. The project-level lookup right above it
already falls back; the per-package one does not.

**Independent argument.** It is a one-line inconsistency with the code
immediately above it, and the platform check a few lines below already rejects
pods that genuinely do not support the target. Best value per line on this
page, and the difference between third-party modules working or not.

### 5. Codegen should not assume `ios`

**Part of the 10 build files.**

`generate-artifacts-executor` hardcodes the platform in places. Small,
mechanical, same argument as 3 and 4.

## What this adds up to

If asks 1 to 4 landed, the fork's modified-file count falls from **195 to
about 45**, and what remains is the part nobody else wants: the
`TARGET_OS_OSX` gates and the AppKit-specific behaviour, which is where the
real macOS work lives and where it belongs.

That is the shape to aim for. A fork of 45 files is one that rebases in an
afternoon.

## Sequencing

Ask 4 first. It is the smallest, the most obviously a bug rather than a
feature request, and it establishes that this fork sends good patches before
asking for anything large.

Then 3 and 5, which are the same kind of change and can go together.

Then 2, which needs a small design conversation about the predicate's name and
where it lives.

Then 1, which needs a real proposal — probably a discussion in
`react-native-community/discussions-and-proposals` rather than a pull request,
because it touches a lot of surface and the argument is about API policy for
out-of-tree platforms rather than about any one file.

## What cannot be upstreamed

The `TARGET_OS_OSX` gates and the AppKit behaviour behind them — the field
editor, the scroll view hosting, the responder chain, the menu — are this
fork's actual content. They are not upstream's problem and should not be
proposed as such.

The Expo patch that used to be listed here is obsolete: since the compatibility
layer was split into a public and a private half, `expo-modules-core` compiles
against this fork unmodified. Nothing is owed there any more.
