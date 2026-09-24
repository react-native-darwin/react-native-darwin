# UIKitCompat

A UIKit implementation backed by AppKit, so that unmodified React Native source
compiles for the `macosx` SDK.

## Why the names are UIKit's

There is no `UIKit.framework` in the macOS SDK:

```
$ ls $(xcrun --show-sdk-path --sdk macosx)/System/Library/Frameworks | grep -i uikit
(nothing)
```

So `UIView`, `UIColor`, `UIScrollView` are free identifiers in a macOS build.
Taking them means upstream keeps its `#import <UIKit/UIKit.h>` and its
`UIView *` declarations, and needs no edit.

`microsoft/react-native-macos` took the other path — it introduced
`RCTPlatformView`, `RCTUIView`, `RCTUIColor` — and then had to edit 538 upstream
files to use them. That is the cost this directory exists to avoid.

`macos/tests/run.sh` asserts the SDK is still free of UIKit before building. If
Apple ever ships UIKit for the macOS SDK, that check fails loudly rather than
producing a confusing duplicate-symbol error.

## The three tiers

Put each symbol in the highest tier that works. See `MACOS-FORK.md` section 4.4.

| Tier | Mechanism | Where |
|---|---|---|
| 1 | `@compatibility_alias` plus a category for what is missing | `UIKitDefines.h`, `UIColor.h`, `UIImage.h`, `UIEvent.h` |
| 2 | `enum` and `#define` constants | `UIKitDefines.h`, `UIAccessibility.h` |
| 3 | A real class subclassing the AppKit equivalent | `UIView.h`, `UIScrollView.h`, `UIGraphics.h` |

Use `@compatibility_alias`, never `#define`, for types. It is a real alias the
compiler understands, so diagnostics stay readable and categories attach.

## Alias or subclass?

The rule: **if AppKit ever hands you one, it must be an alias.**

`UIImage` is an alias for `NSImage` even though `NSImage` lacks `-scale` and a
stable `-CGImage`. A subclass would be wrong, because `+[NSImage imageNamed:]`,
pasteboard reads, and `NSImageRep` conversions all return plain `NSImage`
instances. Those would be statically typed as `UIImage *` and would then fail on
the first `-scale`. An alias plus a category means every `NSImage` answers.

`UIView` is a subclass, because it needs storage and needs to override
`-isFlipped`, `-updateLayer` and `-layout`. But note that the UIKit *surface*
also lives in a category on `NSView`, for exactly the reason above:
`-[NSView subviews]` returns plain `NSView`s that AppKit created, and upstream
iterates them as `UIView *`.

## What the shim cannot fix

- `NSView` is not flipped and not layer-backed. `UIView` fixes both for views
  React Native creates; views AppKit creates keep AppKit behaviour.
- `NSScrollView` scrolls a `documentView` inside a `clipView`. `UIScrollView`'s
  `contentView` means something different from `NSScrollView`'s.
- There is no `UITouch`. `UITouch` here is synthesised from `NSEvent` and
  carries only what a mouse can express.
- There is no memory-warning notification. The symbol exists and never fires.
- There is no true background state. `UIApplicationState` only ever reports
  Active or Inactive.

## Tests

```
./macos/tests/run.sh
```

Builds with `-Werror` and runs 31 behavioural checks. The test file is written
in upstream React Native's own idiom, including the unmodified
`#import <UIKit/UIKit.h>`, so a passing build is evidence about upstream source
and not just about the shim.
