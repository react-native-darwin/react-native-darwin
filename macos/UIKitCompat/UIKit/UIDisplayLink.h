/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <TargetConditionals.h>

#if TARGET_OS_OSX

NS_ASSUME_NONNULL_BEGIN

/**
 * CADisplayLink, for macOS.
 *
 * Upstream already expects this type: RCTAnimatedModuleProvider.mm has a
 * TARGET_OS_OSX branch that imports <React/RCTPlatformDisplayLink.h> and
 * declares an RCTPlatformDisplayLink ivar. The header simply did not exist,
 * because the class lives in the macOS fork. This is that class.
 *
 * Two backends:
 *
 *   macOS 14+   a real CADisplayLink, vended by NSScreen. QuartzCore marks
 *               +displayLinkWithTarget:selector: API_UNAVAILABLE(macos), so
 *               the class method cannot be called directly even though the
 *               class exists.
 *   earlier     an NSTimer at the screen's refresh rate. Not vsync-locked, but
 *               it drives animation at roughly the right cadence, which is what
 *               React Native falls back to on iOS when no link is available.
 */
// RCTPlatformDisplayLink is declared in RCTPlatformTypes.h, the public half:
// third-party code imports <React/RCTPlatformDisplayLink.h> and expects the
// type, the way it does against react-native-macos. The implementation stays
// here.

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_OSX
