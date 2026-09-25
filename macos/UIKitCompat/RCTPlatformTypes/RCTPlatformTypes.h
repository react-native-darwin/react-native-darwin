/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * The platform type vocabulary, naming no UIKit type.
 *
 * This is the half of the compatibility layer that is safe to make public.
 * The other half -- <UIKit/UIKit.h>, which declares `UIView` and forty-odd
 * more -- is not: `@compatibility_alias` is a hard error on redefinition, so
 * any library declaring the same names cannot coexist with it in one
 * translation unit. expo-modules-core declares exactly those names, for
 * exactly the same reason, and fails to compile.
 *
 * So the names an *installed* header is allowed to use live here. They are the
 * same names react-native-macos uses, so third-party code written against that
 * fork compiles unchanged -- and because nothing below mentions UIKit, this
 * header can go on every pod's search path without claiming anything.
 *
 * See macos/PLAN-drop-uikit-aliases.md.
 */

#pragma once

#import <TargetConditionals.h>

#if TARGET_OS_OSX

#import <AppKit/AppKit.h>

@compatibility_alias RCTUIColor NSColor;
@compatibility_alias RCTPlatformColor NSColor;
@compatibility_alias RCTUIImage NSImage;
@compatibility_alias RCTPlatformImage NSImage;
@compatibility_alias RCTPlatformView NSView;
@compatibility_alias RCTPlatformWindow NSWindow;
@compatibility_alias RCTPlatformViewController NSViewController;

#else

#import <UIKit/UIKit.h>

@compatibility_alias RCTUIColor UIColor;
@compatibility_alias RCTPlatformColor UIColor;
@compatibility_alias RCTUIImage UIImage;
@compatibility_alias RCTPlatformImage UIImage;
@compatibility_alias RCTPlatformView UIView;
@compatibility_alias RCTPlatformWindow UIWindow;
@compatibility_alias RCTPlatformViewController UIViewController;

#endif // TARGET_OS_OSX
