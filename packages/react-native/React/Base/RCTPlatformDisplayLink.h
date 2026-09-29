/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS
//
// RCTAnimatedModuleProvider.mm already imports <React/RCTPlatformDisplayLink.h>
// behind TARGET_OS_OSX -- upstream anticipates this type but does not ship it.
// The class itself lives in the macOS compatibility layer; this is the entry
// point upstream expects.
//
// On every other Apple platform RCTPlatformDisplayLink is an alias for
// CADisplayLink, supplied by the force-included prelude, so importing this
// header is harmless there.

#pragma once

#include <TargetConditionals.h>

#if TARGET_OS_OSX
#import <RCTPlatformTypes/RCTPlatformTypes.h> // [macOS] the public half, which
// declares RCTPlatformDisplayLink. Importing <UIKit/UIKit.h> here would reach the shim
// inside this fork and an empty header everywhere else, so a third-party pod
// got nothing -- which is how react-native-worklets failed to build.
#else
#import <QuartzCore/QuartzCore.h>
#endif

// macOS]
