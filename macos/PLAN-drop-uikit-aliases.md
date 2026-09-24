# Migrating off `@compatibility_alias`

## Why

A dependency must not claim global names. This fork declares
`@compatibility_alias UIView NSView` and forty-odd more, in a header it puts on
every pod's search path. Any other library that declares the same names -- and
`expo-modules-core` does, for the same reason -- fails to compile with
`conflicting types for alias 'UIView'`. There is no way to yield: the
preprocessor cannot ask whether an alias already exists.

That makes adopting this fork a breaking change for a library that did nothing
wrong, and requiring a patch to somebody else's package is not a shipping
story. The aliases have to stop escaping.

Measured, not assumed: excluding a pod from the shim does not help. Its
headers then fail on `could not build module 'React'`, because React Native's
own public headers are written in terms of `UIView *`. The aliases have to be
visible wherever RN's headers are -- which is everywhere -- for as long as
RN's headers spell types that way.

That is the thing to change.

## End state

`<UIKit/UIKit.h>` becomes **private to this fork's own pods**. Nothing a third
party compiles ever sees it, so nothing it declares can conflict.

Two properties make that possible:

  1. **No installed header names a UIKit type.** Public headers use the names
     this fork owns -- `RCTPlatformView`, `RCTUIColor`, `RCTPlatformImage` --
     which are already the convention here and already match
     react-native-macos, so third-party code written against that fork still
     compiles. Those names must come from a header reachable by *every* pod,
     including the ones below React-Core; see phase 1.
  2. **`React/RCTUIKit.h` stops importing `<UIKit/UIKit.h>`.** It defines the
     `RCT*` names from AppKit directly. It is the header everyone else imports,
     and today it is how the aliases reach them.

The shim stays exactly as it is for implementation files. `.m` and `.mm` inside
this fork keep writing `UIView *`, and keep getting it from the shim through
the `-include` prelude -- which is what makes the fork small. Only the
*boundary* changes.

## Acceptance test

One test, and it is the whole point:

> A stock BareExpo, with **no patch** to `expo-modules-core`, builds and runs.

Plus, mechanically: no header installed into `Pods/Headers/Public` matches
`\bUI[A-Z]`, and `React-UIKitCompat.podspec` vends the UIKit directory as
private headers.

## Cost

Measured against `0.87.1-rc.14`:

| | |
|---|---|
| Public headers naming a UIKit type | **58** |
| Implementation files naming one | 111 -- **unchanged**, they keep the shim |
| Distinct names to map in headers | ~8 cover it: `UIView` (74 uses), `UIColor` (34), `UIImage` (28), `UIEdgeInsets` (21), `UIFont` (16), `UIViewController` (15), `UIScrollView`, `UIWindow` |

58 files, against 538 for the full rename react-native-macos does. The economy
holds because implementations keep the shim; only the boundary is renamed.

## Phases

### 1. Give the neutral names a home every pod can reach

Run first, because the obvious version of this plan does not work. Piloting
`React-graphics` -- one header, `UIColor *` to `RCTUIColor *` -- fails with
`'React/RCTUIKit.h' file not found`. The `RCT*` names live in React-Core, and
React-graphics sits below it in the dependency graph. Renaming the boundary
without somewhere to put the names just moves the breakage.

So `React-UIKitCompat` grows a second, **public** header -- call it
`RCTPlatformTypes.h` -- defining `RCTPlatformView`, `RCTUIColor`,
`RCTPlatformImage` and the rest straight from AppKit. It names no UIKit type,
so it is safe to put on every pod's search path, which is what makes it
reachable from the bottom of the graph.

The UIKit aliases stay in the same pod, private. One pod, two headers, and the
split between them is exactly the leak boundary.

Then re-run the `React-graphics` pilot against it: rename the header, drop the
shim from that pod's search path, build. Cheap, and it either works or finds
the next hole before 58 files are touched.

**Done.** `RCTPlatformTypes.h` exists, vended by `React-UIKitCompat` under its
own header dir, and `RCTPlatformColorUtils.h` -- the one React-graphics header
that named a UIKit type -- now imports it and uses `RCTUIColor *`. HelloWorld
builds and runs.

Two things the pilot settled, both of which shape the rest:

  - **The split has to be exclusive.** Naming `RCTPlatformView` in both halves
    is an error even though both name `NSView`, so `UIKit/UIView.h`,
    `RCTPlatformViewCompat.h` and `React/RCTUIKit.h` all had to stop declaring
    the vocabulary and defer to the one header. That is a one-time cost,
    already paid.
  - **Import placement matters.** `RCTPlatformTypes.h` has to be imported at
    the top of a header, not where the alias used to sit: inside a
    `NS_ASSUME_NONNULL_BEGIN` region clang rejects it outright.

### 2. Rename the boundary

The 58 headers, by name, most-used first. Each is `UIView *` to
`RCTPlatformView *` and so on -- the same edit the budget linter already
permits, since `RCTPlatformView` is an NSView alias rather than a concrete
class.

`RCTUIKit.h` last: it stops importing `<UIKit/UIKit.h>` and defines its names
from AppKit. That is the commit that actually closes the leak.

### 3. Make the shim private

`React-UIKitCompat.podspec` moves `UIKit/*.h` from `source_files` to
`private_header_files`, and `apply_uikit_compat` stops adding the search path
and prelude to pods that are not ours. Third-party pods keep building, because
after phase 2 nothing they import mentions a UIKit type.

### 4. Re-baseline the checks

  - `MAX_UPSTREAM_FILES_MODIFIED` rises by roughly 58. Worth restating plainly
    rather than hiding: the fork gets bigger to stop being invasive, and that
    is the right trade.
  - Budget rule 5 currently bans `RCTUIView *` as a pointer type to stop
    exactly this spread. It needs rewriting: `RCTPlatformView *` in a header is
    now the goal, not the violation. `RCTUIView *` stays banned -- it is the
    concrete class, and that distinction is what keeps reanimated working.
  - Add a rule: no installed public header matches `\bUI[A-Z]`. That is the
    invariant this whole migration buys, and it should fail a build.

### 5. Validate against real dependents

BareExpo unpatched is the headline. Then `react-native-reanimated`,
`react-native-safe-area-context`, and `react-native-screens` -- all three
declare their own UIKit compatibility and are exactly the libraries this was
breaking.

## What this does not fix

Third-party code that writes `UIView *` when calling into React Native still
needs *somebody* to define it. After this migration that somebody is the
library itself, or react-native-macos's own headers -- not us. That is the
correct arrangement and the one react-native-macos already relies on.

## Until it lands

There is no partial mitigation. Narrowing where the shim is injected does not
work (proven above), so an app using both this fork and `expo-modules-core`
needs the `__has_include` guard applied to `expo-modules-core` until phase 2
is done. That guard is correct for Expo on its own terms and should be
upstreamed regardless.
