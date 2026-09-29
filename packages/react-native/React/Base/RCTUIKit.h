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

// This header is imported by third-party code, so it must not reach the UIKit
// shim: that is exactly how the aliases used to escape into everyone else's
// translation units. Everything below is built from RCTPlatformTypes.h, the
// half of the compatibility layer that names no UIKit type.
// See macos/PLAN-drop-uikit-aliases.md.
#import <RCTPlatformTypes/RCTPlatformTypes.h>

// RCTUIView and RCTPlatformView come from RCTPlatformTypes.h, with the same
// split react-native-macos uses: RCTPlatformView is NSView, and RCTUIView is
// the concrete subclass carrying the UIKit method surface. See MACOS-FORK.md
// section 4.5.

// [macOS
// The UIKit names react-native-macos declares on macOS, and that libraries
// written against it expect React Native to provide.
//
// This is not a retreat from the split between the public and private halves.
// The split is about names two parties might *both* declare; this is the set
// the ecosystem has already agreed belongs to React Native. The proof is that
// it is disjoint from what libraries declare for themselves --
// expo-modules-core declares UIView, UIColor, UIImage, UIWindow, UIResponder,
// UIImageView and UIHostingController, none of which appear below, and guards
// the single overlap (UIApplication, a macro) with #ifndef.
//
// Without these, a library that declares its own UIView still fails on the
// first `UIViewController *` in its headers, because nothing defines it. That
// is exactly how expo-modules-core failed against this fork.
//
// Suppressed inside this fork's own pods, which already have the full shim.
#ifndef RCT_UIKIT_COMPAT_SHIM

#define UIApplicationDidBecomeActiveNotification NSApplicationDidBecomeActiveNotification
#define UIApplicationDidEnterBackgroundNotification NSApplicationDidHideNotification
#define UIApplicationDidFinishLaunchingNotification NSApplicationDidFinishLaunchingNotification
#define UIApplicationWillResignActiveNotification NSApplicationWillResignActiveNotification
#define UIApplicationWillEnterForegroundNotification NSApplicationWillUnhideNotification
#define UIFontDescriptorFamilyAttribute NSFontFamilyAttribute
#define UIFontDescriptorNameAttribute NSFontNameAttribute
#define UIFontDescriptorSizeAttribute NSFontSizeAttribute
#define UIFontDescriptorTraitsAttribute NSFontTraitsAttribute
#define UIFontDescriptorFeatureSettingsAttribute NSFontFeatureSettingsAttribute
#define UIFontSymbolicTrait NSFontSymbolicTrait
#define UIFontWeightTrait NSFontWeightTrait
#define UIFontFeatureTypeIdentifierKey NSFontFeatureTypeIdentifierKey
#define UIFontFeatureSelectorIdentifierKey NSFontFeatureSelectorIdentifierKey
#define UIFontWeightUltraLight NSFontWeightUltraLight
#define UIFontWeightThin NSFontWeightThin
#define UIFontWeightLight NSFontWeightLight
#define UIFontWeightRegular NSFontWeightRegular
#define UIFontWeightMedium NSFontWeightMedium
#define UIFontWeightSemibold NSFontWeightSemibold
#define UIFontWeightBold NSFontWeightBold
#define UIFontWeightHeavy NSFontWeightHeavy
#define UIFontWeightBlack NSFontWeightBlack
#define UIFontDescriptorSystemDesign NSFontDescriptorSystemDesign
#define UIFontDescriptorSystemDesignDefault NSFontDescriptorSystemDesignDefault
#define UIFontDescriptorSystemDesignSerif NSFontDescriptorSystemDesignSerif
#define UIFontDescriptorSystemDesignRounded NSFontDescriptorSystemDesignRounded
#define UIFontDescriptorSystemDesignMonospaced NSFontDescriptorSystemDesignMonospaced
#define UIActivityIndicatorView NSProgressIndicator
#define UIUserInterfaceLayoutDirection NSUserInterfaceLayoutDirection
@compatibility_alias UIAccessibilityCustomAction NSAccessibilityCustomAction;
@compatibility_alias UIFont NSFont;
@compatibility_alias UIViewController NSViewController;
@compatibility_alias UIFontDescriptor NSFontDescriptor;
#define UIEvent NSEvent
#define UITouchType NSTouchType
#define UIEventButtonMask NSEventButtonMask
#define UIKeyModifierFlags NSEventModifierFlags
#define UIGestureRecognizer NSGestureRecognizer
#define UIGestureRecognizerDelegate NSGestureRecognizerDelegate
#define UIApplication NSApplication
@compatibility_alias UIBezierPath NSBezierPath;

#endif // RCT_UIKIT_COMPAT_SHIM
// macOS]

// The rest of the RCTUI* vocabulary, renamed from the neutral names.
@compatibility_alias RCTUIScrollView RCTPlatformScrollView;
@compatibility_alias RCTUISlider RCTPlatformSlider;
@compatibility_alias RCTUILabel RCTPlatformLabel;
@compatibility_alias RCTUISwitch RCTPlatformSwitch;
@compatibility_alias RCTUIActivityIndicatorView RCTPlatformActivityIndicatorView;
@compatibility_alias RCTUITouch RCTPlatformTouch;
@compatibility_alias RCTUIImageView RCTPlatformImageView;
@compatibility_alias RCTUIPanGestureRecognizer RCTPlatformPanGestureRecognizer;
@compatibility_alias RCTUIGraphicsImageRenderer RCTPlatformGraphicsImageRenderer;
@compatibility_alias RCTUIGraphicsImageRendererFormat RCTPlatformGraphicsImageRendererFormat;
@compatibility_alias RCTUIGraphicsImageRendererContext RCTPlatformGraphicsImageRendererContext;
@compatibility_alias RCTUIApplication RCTPlatformApplication;
// The whole RCTPlatform* vocabulary -- RCTPlatformSwitch, RCTPlatformWindow,
// RCTPlatformViewController and the rest -- comes from RCTPlatformTypes.h,
// imported above. Declaring any of it a second time is a hard error even when
// both declarations name the same class, so this header must not repeat it.

// Protocols and non-class names cannot use @compatibility_alias.
#define RCTUIScrollViewDelegate RCTPlatformScrollViewDelegate
typedef RCTPlatformAccessibilityTraits RCTUIAccessibilityTraits;
typedef void (^RCTUIGraphicsImageDrawingActions)(RCTPlatformGraphicsImageRendererContext *_Nonnull rendererContext);

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
#import <RCTPlatformTypes/RCTPlatformTypes.h>

// RCTUIColor, RCTPlatformColor, RCTUIImage and RCTPlatformImage come from
// RCTPlatformTypes.h, which is where the whole vocabulary is declared on both
// platforms. RCTUIView and RCTPlatformView come from the force-included
// prelude here.

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
// The whole RCTPlatform* vocabulary -- RCTPlatformSwitch, RCTPlatformWindow,
// RCTPlatformViewController and the rest -- comes from RCTPlatformTypes.h,
// imported above. Declaring any of it a second time is a hard error even when
// both declarations name the same class, so this header must not repeat it.

#define RCTUIScrollViewDelegate UIScrollViewDelegate
typedef UIAccessibilityTraits RCTUIAccessibilityTraits;
typedef UIGraphicsImageRendererContext RCTUIGraphicsImageRendererContext;
typedef UIGraphicsImageDrawingActions RCTUIGraphicsImageDrawingActions;

#endif // TARGET_OS_OSX
