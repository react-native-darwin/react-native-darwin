/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * <UIKit/UIKit.h> for everybody who is not this fork.
 *
 * React Native's headers import UIKit, and on macOS that import has to resolve
 * or nothing downstream compiles. It used to resolve to the real shim, which
 * declares `UIView` and forty-odd more names -- and a dependency must not claim
 * global names. Any library declaring the same ones could not compile
 * alongside this fork; expo-modules-core, reanimated, safe-area-context and
 * screens all declare them, for the same reason and just as legitimately.
 *
 * So third-party pods get this file instead. It satisfies the import and
 * declares nothing, which is the whole point: a library is free to declare
 * `UIView` itself, exactly as it does against microsoft/react-native-macos.
 *
 * Installed React Native headers name no UIKit type any more -- they use the
 * RCTPlatform* vocabulary below -- so nothing they contain needs more than
 * this. The real shim stays private to this fork's own pods, where the
 * implementation files still write `UIView` and get it from the force-included
 * prelude.
 *
 * See macos/PLAN-drop-uikit-aliases.md.
 */

#pragma once

#import <TargetConditionals.h>

#if TARGET_OS_OSX

#import <AppKit/AppKit.h>
#import <RCTPlatformTypes/RCTPlatformTypes.h>

#endif // TARGET_OS_OSX
