<h1 align="center">React Native for macOS</h1>

<p align="center">
  <strong>AppKit support for React Native, as a fork that stays small enough to rebase.</strong>
</p>

<p align="center">
  <a href="https://www.npmjs.org/package/react-native-darwin">
    <img src="https://img.shields.io/npm/v/react-native-darwin?color=brightgreen&label=npm%20package" alt="Current npm package version." />
  </a>
  <a href="https://github.com/react-native-darwin/react-native-darwin/blob/HEAD/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT licensed." />
  </a>
</p>

---

This is a fork of [facebook/react-native](https://github.com/facebook/react-native) that
runs on macOS, drawing with AppKit. It is published to npm as **`react-native-darwin`** and
installed under the **`react-native-macos`** alias, so an app can keep upstream
`react-native` for iOS and Android and add this one for the Mac.

## Why this exists

React Native has no macOS target. The established answer,
[microsoft/react-native-macos](https://github.com/microsoft/react-native-macos), works — and
this project owes it a great deal — but it carries a large, permanent diff against upstream:
it renames React Native's platform types (`UIView` to `RCTPlatformView` and so on) throughout
the tree, which means touching around 500 upstream files and re-resolving them on every
rebase.

This fork takes the other route. The macOS SDK ships no `UIKit.framework`, so `UIView`,
`UIColor` and the rest are free identifiers on this platform. A compatibility layer defines
them as AppKit types from a header directory named `UIKit`, which means React Native's own
implementation files compile unchanged — no rename, no diff.

The result is measured, not asserted. Against the upstream release each forks:

| | react-native-darwin | react-native-macos |
|---|---|---|
| Upstream files modified | **189** | **500** |
| Lines added | **2,850** | **14,876** |
| Lines removed | **439** | **2,053** |

Two things that table does not say, and should:

- A meaningful part of the gap is **coverage, not elegance**. Splitting those diffs by what
  the changes actually do, react-native-macos has 326 files of real macOS work to this
  fork's 73. It has been maintained for years and supports more surface.
- The comparison is against different base versions — 0.87 here, 0.81 there — because
  react-native-macos has not shipped 0.87 yet. Upstream patch-to-patch churn in the same
  directories is about 16 files, so it does not move the conclusion.

## A dependency must not claim global names

Defining `UIView` has an obvious hazard: any other library that defines it too stops
compiling, and `@compatibility_alias` is a hard error on redeclaration even when both
declarations name the same class. `expo-modules-core`, `react-native-reanimated`,
`react-native-safe-area-context` and `react-native-screens` all declare those names, for the
same reason and just as legitimately.

So the compatibility layer is split in two, along a line that is not obvious but is exact:

- Only `@compatibility_alias`, a class `@interface`, a `@protocol` and an `NS_ENUM` are
  errors on *re*declaration. Those are **private** to this fork's own pods.
- A `typedef`, a `#define`, an inline function and a category can all be declared twice, as
  long as the declarations match. Those are **public**, and every pod gets them.

Installed headers are written in a neutral vocabulary — `RCTPlatformView`, `RCTUIColor` —
which is the same vocabulary react-native-macos uses, so third-party code written against
that fork compiles here unchanged. A library that declares its own `UIView` compiles too.
`macos/ci/check-budget.sh` fails the build if that line is ever crossed.

## Always in sync with React Native core

This fork tracks upstream React Native release for release. That is the whole point of
keeping the diff small: a fork that touches 189 files can be rebased onto a new upstream
version; one that touches 2,000 cannot, and drifts.

The discipline is enforced mechanically rather than promised. Every change must pass
`macos/ci/check-budget.sh`, which fails the build when:

- more upstream files are modified than the budget allows;
- more upstream lines are removed than the budget allows;
- any hunk in an upstream file lacks a `[macOS]` marker explaining it;
- the shim registers a UIKit name with the Objective-C runtime;
- any header outside the private shim makes a declaration a third party could not repeat.

The budgets are written down with the reasoning for every number, and raising one is a
deliberate, reviewed act rather than a side effect. `MACOS-FORK.md` is the contract;
`macos/ROADMAP.md` records what works, what does not, and what was measured.

Nothing here is automated yet: syncing is a rebase a human or agent runs, not a scheduled
job. If you want it to be continuous rather than intentional, that is a CI workflow waiting
to be written.

## AI-maintained

This fork is written and maintained by an AI agent, working from the contract in
`MACOS-FORK.md` and the budgets in `macos/ci/check-budget.sh`.

That is a statement of fact rather than a selling point, and it is why the guardrails in this
repository are unusually explicit. An agent is good at mechanical breadth — renaming a
vocabulary across 135 headers, or driving a real app with synthetic mouse and key events to
find out whether a component actually works — and bad at noticing that it has quietly
widened the thing it was meant to keep narrow. The linter exists to make that failure mode
loud. Judgement calls, and the reasoning behind them, are written into the commit messages
and the documents above rather than left implicit.

Read the code with that in mind, and please report anything that looks wrong.

## Getting started

```sh
npm install --save-dev react-native-macos@npm:react-native-darwin@next
npx react-native-darwin-init
cd macos && RCT_USE_RN_DEP=1 RCT_USE_PREBUILT_RNCORE=0 pod install
```

Those two `pod install` variables matter: without them CocoaPods resolves the prebuilt React
Core, which is published for iOS only, and the install fails on a platform mismatch.

`react-native-darwin-init` writes a `macos/` directory and a `metro.config.js` that points
the macOS bundle at this package while iOS and Android keep using `react-native`. See
`macos/template/README.md` for what it generates.

## What works

Core components, `Text`, `Image`, `TextInput` (both single and multi-line, with the macOS
props: `submitKeyEvents`, `onPaste`, `pastedTypes`, `grammarCheck`, `clearTextOnSubmit`,
`hideVerticalScrollIndicator` and the three checking-toggle events), `ScrollView`,
`FlatList`, `SectionList`, `Modal`, `Alert` including `promptMacOS`, `Switch`,
`ActivityIndicator`, `Pressable` and the Touchables, `Animated` with the native driver,
`PlatformColor`, `AccessibilityInfo`, key events, mouse events, and drag and drop.

Third-party native modules autolink, build and run — `react-native-safe-area-context` is
verified end to end, unmodified.

`macos/ROADMAP.md` is the current, measured state, including what is still unverified.

## Documentation

For React Native itself — components, APIs, guides — use the
[upstream documentation](https://reactnative.dev/docs/getting-started). Everything there
applies. This repository documents only what is macOS-specific:

- `MACOS-FORK.md` — the contract: what may be changed, and the budgets
- `macos/ROADMAP.md` — what works, what does not, what was measured
- `macos/PLAN-drop-uikit-aliases.md` — why the compatibility layer is split the way it is
- `macos/PLAN-upstream.md` — which changes belong upstream, ranked by what they would remove

## License

React Native, and this fork, are MIT licensed. See [LICENSE](./LICENSE).
