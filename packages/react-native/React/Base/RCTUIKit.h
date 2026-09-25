/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] Compatibility header for third-party code written against
// microsoft/react-native-macos.
//
// That fork routes every platform type through <React/RCTUIKit.h>: RCTUIColor,
// RCTUIImage, RCTUIView and friends. This fork does not need those names --
// it serves a real UIKit header set, so upstream and iOS-shaped code compiles
// with the names it already uses. But published packages do import this header
// by name, and a macOS React Native that cannot build react-native-webview or
// expo-modules-core is not much use, so the names are provided here.
//
// This is the only file in the fork that exists purely for other people's code.
// macOS]

#pragma once

#import <TargetConditionals.h>

// react-native-macos's RCTUIKit.h pulls these in transitively, and third-party
// code relies on that: react-native-svg's RNSVGUIKit.h imports only RCTUIKit.h
// and then calls RCTAssert.
#import <React/RCTAssert.h>
#import <React/RCTDefines.h>

#if TARGET_OS_OSX

#import <AppKit/AppKit.h>
#import <UIKit/UIKit.h> // The AppKit-backed shim: UIView, UIColor, UIImage, ...

// Colour and image come from RCTPlatformTypes.h, the half of the compatibility
// layer that names no UIKit type and is therefore safe on every pod's search
// path. Declaring them here as well is an error even though both spellings
// name NSColor. See macos/PLAN-drop-uikit-aliases.md.
#import <RCTPlatformTypes/RCTPlatformTypes.h>

// RCTUIView and RCTPlatformView are declared by the UIKit shim imported above,
// with the same split react-native-macos uses: RCTPlatformView is NSView, and
// RCTUIView is the concrete subclass carrying the UIKit method surface. See
// MACOS-FORK.md section 4.5.

// The rest of the RCTUI* / RCTPlatform* vocabulary. Each one already exists in
// the shim under its UIKit name, so these are pure renames -- which is the
// whole point: react-native-macos had to invent the names because it has no
// UIKit to borrow them from.
@compatibility_alias RCTUIScrollView UIScrollView;
@compatibility_alias RCTUISlider UISlider;
@compatibility_alias RCTUILabel UILabel;
@compatibility_alias RCTUISwitch UISwitch;
@compatibility_alias RCTUIActivityIndicatorView UIActivityIndicatorView;
@compatibility_alias RCTUITouch UITouch;
@compatibility_alias RCTUIImageView UIImageView;
@compatibility_alias RCTUIPanGestureRecognizer UIPanGestureRecognizer;
@compatibility_alias RCTUIGraphicsImageRenderer UIGraphicsImageRenderer;
@compatibility_alias RCTUIGraphicsImageRendererFormat UIGraphicsImageRendererFormat;
@compatibility_alias RCTUIGraphicsImageRendererContext UIGraphicsImageRendererContext;
@compatibility_alias RCTUIApplication UIApplication;
// RCTPlatformWindow and RCTPlatformViewController also come from
// RCTPlatformTypes.h.
@compatibility_alias RCTPlatformSwitch UISwitch;

// Protocols and non-class names cannot use @compatibility_alias.
#define RCTUIScrollViewDelegate UIScrollViewDelegate
typedef UIAccessibilityTraits RCTUIAccessibilityTraits;
typedef void (^RCTUIGraphicsImageDrawingActions)(UIGraphicsImageRendererContext *rendererContext);

#import <React/RCTConvert.h>

/**
 * react-native-macos spells RCTConvert's colour and image entry points with
 * AppKit names, and third-party code calls them that way -- react-native-svg
 * does `[RCTConvert RNSVGColor:json]`, where RNSVGColor expands to NSColor.
 *
 * This fork keeps the UIKit names, because upstream React Native calls those
 * and `UIColor` is already an alias for `NSColor`. A `@compatibility_alias`
 * renames a type, not a selector, so `+UIColor:` does not answer to `NSColor:`
 * and the two spellings have to be bridged explicitly.
 */
@interface RCTConvert (RCTUIKitCompat)

+ (nullable NSColor *)NSColor:(nullable id)json;
+ (nullable NSImage *)NSImage:(nullable id)json;

@end

#else

#import <UIKit/UIKit.h>

@compatibility_alias RCTUIColor UIColor;
@compatibility_alias RCTPlatformColor UIColor;
@compatibility_alias RCTUIImage UIImage;
@compatibility_alias RCTPlatformImage UIImage;
// RCTUIView and RCTPlatformView come from the force-included prelude here.

@compatibility_alias RCTUIScrollView UIScrollView;
@compatibility_alias RCTUISlider UISlider;
@compatibility_alias RCTUILabel UILabel;
@compatibility_alias RCTUISwitch UISwitch;
@compatibility_alias RCTUIActivityIndicatorView UIActivityIndicatorView;
@compatibility_alias RCTUITouch UITouch;
@compatibility_alias RCTUIImageView UIImageView;
@compatibility_alias RCTUIPanGestureRecognizer UIPanGestureRecognizer;
@compatibility_alias RCTUIGraphicsImageRenderer UIGraphicsImageRenderer;
@compatibility_alias RCTUIGraphicsImageRendererFormat UIGraphicsImageRendererFormat;
@compatibility_alias RCTUIApplication UIApplication;
// RCTPlatformWindow and RCTPlatformViewController also come from
// RCTPlatformTypes.h.
@compatibility_alias RCTPlatformSwitch UISwitch;

#define RCTUIScrollViewDelegate UIScrollViewDelegate
typedef UIAccessibilityTraits RCTUIAccessibilityTraits;
typedef UIGraphicsImageRendererContext RCTUIGraphicsImageRendererContext;
typedef UIGraphicsImageDrawingActions RCTUIGraphicsImageDrawingActions;

#endif // TARGET_OS_OSX
