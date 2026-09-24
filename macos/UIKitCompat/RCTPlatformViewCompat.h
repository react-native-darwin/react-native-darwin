/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Force-included into every Objective-C translation unit, on every Apple
 * platform, via -include in OTHER_CFLAGS.
 *
 * Two jobs:
 *
 *   1. On macOS, put the UIKit compatibility layer in scope everywhere. Not
 *      every upstream file imports <UIKit/UIKit.h> -- some reach only for
 *      QuartzCore or Foundation and still expect UIKit names, because on iOS a
 *      transitive import supplies them. A build flag fixes all of those at
 *      once, with no upstream edit.
 *
 *   2. On every platform, define the RCTPlatform* concrete types:
 *
 *        RCTPlatformView            iOS: UIView          macOS: flipped, layer-backed NSView
 *        RCTPlatformDisplayLink     iOS: CADisplayLink   macOS: CADisplayLink on 14+, NSTimer below
 *        RCTPlatformTouchesForEvent iOS: -allTouches     macOS: synthesised from NSEvent
 *
 *      Both are aliases on iOS, so those builds gain two names and change in no
 *      other way. Upstream already uses the RCTPlatformDisplayLink name itself:
 *      RCTAnimatedModuleProvider.mm ships a TARGET_OS_OSX branch for it.
 *
 * Guarded on __OBJC__ so force-including it into a .c or .cpp translation unit
 * is a no-op rather than a syntax error.
 */

#pragma once

#include <TargetConditionals.h>

#ifdef __OBJC__

#if TARGET_OS_OSX

// Resolves to macos/UIKitCompat/UIKit/UIKit.h, which declares RCTPlatformView.
#import <UIKit/UIKit.h>

#else

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>

// On iOS, tvOS and visionOS the concrete classes are simply the UIKit ones.
@compatibility_alias RCTPlatformView UIView;
@compatibility_alias RCTPlatformDisplayLink CADisplayLink;

// -[UIEvent allTouches] is unavailable under its own name on macOS, because
// NSEvent already declares -allTouches with a different element type. Call
// sites use this function on every platform; here it is exactly the property.
NS_INLINE NSSet<UITouch *> *_Nullable RCTPlatformTouchesForEvent(UIEvent *_Nullable event)
{
  return event.allTouches;
}

#endif // TARGET_OS_OSX

#endif // __OBJC__
