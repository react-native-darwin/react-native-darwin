/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Tier 1 and Tier 2 of the UIKit compatibility layer: type aliases, constants
 * and enums that map directly onto an existing AppKit or Foundation symbol.
 *
 * Nothing in this file allocates or implements behaviour. If a symbol needs a
 * real implementation it belongs in its own header, not here.
 *
 * See MACOS-FORK.md section 4.4.
 */

#pragma once

#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Tier 1: type aliases

// These AppKit types are close enough to their UIKit counterparts that an alias
// is correct. Where a handful of methods are missing, a category supplies them
// rather than a subclass -- a subclass would change the type identity that
// AppKit itself hands back to us.

@compatibility_alias UIFont NSFont;
@compatibility_alias UIFontDescriptor NSFontDescriptor;
@compatibility_alias UIBezierPath NSBezierPath;
@compatibility_alias UIViewController NSViewController;
@compatibility_alias UIWindow NSWindow;
@compatibility_alias UIScreen NSScreen;
@compatibility_alias UIGestureRecognizer NSGestureRecognizer;
@compatibility_alias UIPanGestureRecognizer NSPanGestureRecognizer;
@compatibility_alias UIPasteboard NSPasteboard;
@compatibility_alias UIResponder NSResponder;
@compatibility_alias UITextChecker NSSpellChecker;

typedef NSFontSymbolicTraits UIFontDescriptorSymbolicTraits;
typedef NSFontWeight UIFontWeight;
typedef NSEventModifierFlags UIKeyModifierFlags;
// AppKit's NSEventButtonMask only covers pen buttons -- there is no Primary or
// Secondary constant to alias, so these carry UIKit's own bit values and are
// matched against NSEvent.buttonNumber at the point of use.
typedef NS_OPTIONS(NSUInteger, UIEventButtonMask) {
  UIEventButtonMaskPrimary = 1 << 0,
  UIEventButtonMaskSecondary = 1 << 1,
};
typedef NSUserInterfaceLayoutDirection UIUserInterfaceLayoutDirection;
typedef NSInteger UIViewAnimationCurve;

// macOS has no scenes. Declared as classes rather than typedefs because
// upstream uses them as object pointers; they are never instantiated.
@interface UIScene : NSObject
@end
@interface UIWindowScene : UIScene
@end

typedef NS_ENUM(NSInteger, UIButtonType) {
  UIButtonTypeCustom = 0,
  UIButtonTypeSystem,
  UIButtonTypeDetailDisclosure,
  UIButtonTypeInfoLight,
  UIButtonTypeInfoDark,
  UIButtonTypeContactAdd,
  UIButtonTypeClose,
};

// AppKit's click recogniser is the closest equivalent of a single tap.
@compatibility_alias UITapGestureRecognizer NSClickGestureRecognizer;
@compatibility_alias UILongPressGestureRecognizer NSPressGestureRecognizer;

#pragma mark - Tier 2: geometry

typedef NSEdgeInsets UIEdgeInsets;

#define UIEdgeInsetsZero NSEdgeInsetsZero
#define UIViewNoIntrinsicMetric NSViewNoIntrinsicMetric

NS_INLINE UIEdgeInsets UIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right)
{
  return NSEdgeInsetsMake(top, left, bottom, right);
}

NS_INLINE CGRect UIEdgeInsetsInsetRect(CGRect rect, UIEdgeInsets insets)
{
  rect.origin.x += insets.left;
  rect.origin.y += insets.top;
  rect.size.width -= (insets.left + insets.right);
  rect.size.height -= (insets.top + insets.bottom);
  return rect;
}

NS_INLINE BOOL UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsets a, UIEdgeInsets b)
{
  return NSEdgeInsetsEqual(a, b);
}

NS_INLINE NSString *NSStringFromCGSize(CGSize size)
{
  return NSStringFromSize(NSSizeFromCGSize(size));
}

NS_INLINE NSString *NSStringFromCGRect(CGRect rect)
{
  return NSStringFromRect(NSRectFromCGRect(rect));
}

NS_INLINE NSString *NSStringFromCGPoint(CGPoint point)
{
  return NSStringFromPoint(NSPointFromCGPoint(point));
}

NS_INLINE NSValue *NSValueWithCGRect(CGRect rect)
{
  return [NSValue valueWithRect:NSRectFromCGRect(rect)];
}

NS_INLINE NSValue *NSValueWithCGSize(CGSize size)
{
  return [NSValue valueWithSize:NSSizeFromCGSize(size)];
}

NS_INLINE CGRect CGRectValue(NSValue *value)
{
  return NSRectToCGRect(value.rectValue);
}

#pragma mark - Tier 2: application notifications

#define UIApplicationDidBecomeActiveNotification NSApplicationDidBecomeActiveNotification
#define UIApplicationWillResignActiveNotification NSApplicationWillResignActiveNotification
#define UIApplicationDidFinishLaunchingNotification NSApplicationDidFinishLaunchingNotification
#define UIApplicationWillTerminateNotification NSApplicationWillTerminateNotification

// macOS has no true background state. Hiding is the closest analogue, and it is
// what react-native-macos uses. Code that relies on these firing around real
// suspension will not behave the same as on iOS.
#define UIApplicationDidEnterBackgroundNotification NSApplicationDidHideNotification
#define UIApplicationWillEnterForegroundNotification NSApplicationWillUnhideNotification

// No AppKit equivalent exists. Declared so upstream observers compile; it never fires.
extern NSNotificationName const UIApplicationDidReceiveMemoryWarningNotification;

#pragma mark - Tier 2: font constants

#define UIFontDescriptorFamilyAttribute NSFontFamilyAttribute
#define UIFontDescriptorNameAttribute NSFontNameAttribute
#define UIFontDescriptorFaceAttribute NSFontFaceAttribute
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

enum {
  UIFontDescriptorTraitItalic = NSFontItalicTrait,
  UIFontDescriptorTraitBold = NSFontBoldTrait,
  UIFontDescriptorTraitCondensed = NSFontCondensedTrait,
  UIFontDescriptorTraitMonoSpace = NSFontMonoSpaceTrait,
};

NS_INLINE UIFont *UIFontWithSize(UIFont *font, CGFloat pointSize)
{
  return [NSFont fontWithDescriptor:font.fontDescriptor size:pointSize];
}

// NSFont exposes no lineHeight. This matches the layout manager's default.
NS_INLINE CGFloat UIFontLineHeight(UIFont *font)
{
  return ceil(font.ascender + ABS(font.descender) + font.leading);
}

#pragma mark - Tier 2: enums

enum {
  UIGestureRecognizerStatePossible = NSGestureRecognizerStatePossible,
  UIGestureRecognizerStateBegan = NSGestureRecognizerStateBegan,
  UIGestureRecognizerStateChanged = NSGestureRecognizerStateChanged,
  UIGestureRecognizerStateEnded = NSGestureRecognizerStateEnded,
  UIGestureRecognizerStateCancelled = NSGestureRecognizerStateCancelled,
  UIGestureRecognizerStateFailed = NSGestureRecognizerStateFailed,
  UIGestureRecognizerStateRecognized = NSGestureRecognizerStateRecognized,
};

enum : NSUInteger {
  UIViewAutoresizingNone = NSViewNotSizable,
  UIViewAutoresizingFlexibleLeftMargin = NSViewMinXMargin,
  UIViewAutoresizingFlexibleWidth = NSViewWidthSizable,
  UIViewAutoresizingFlexibleRightMargin = NSViewMaxXMargin,
  UIViewAutoresizingFlexibleTopMargin = NSViewMinYMargin,
  UIViewAutoresizingFlexibleHeight = NSViewHeightSizable,
  UIViewAutoresizingFlexibleBottomMargin = NSViewMaxYMargin,
};

// UIKit's own numeric values, not AppKit's.
//
// Mapping these straight onto NSViewLayerContentsPlacement looks tidy and is
// wrong: several AppKit placements share a value with
// NSViewLayerContentsRedrawOnSetNeedsDisplay, so ScaleAspectFit and Redraw
// collapse to the same constant and any switch over the enum stops compiling.
// The translation to AppKit happens in -setContentMode:.
typedef NS_ENUM(NSInteger, UIViewContentMode) {
  UIViewContentModeScaleToFill = 0,
  UIViewContentModeScaleAspectFit = 1,
  UIViewContentModeScaleAspectFill = 2,
  UIViewContentModeRedraw = 3,
  UIViewContentModeCenter = 4,
  UIViewContentModeTop = 5,
  UIViewContentModeBottom = 6,
  UIViewContentModeLeft = 7,
  UIViewContentModeRight = 8,
  UIViewContentModeTopLeft = 9,
  UIViewContentModeTopRight = 10,
  UIViewContentModeBottomLeft = 11,
  UIViewContentModeBottomRight = 12,
};

enum : NSInteger {
  UIUserInterfaceLayoutDirectionLeftToRight = NSUserInterfaceLayoutDirectionLeftToRight,
  UIUserInterfaceLayoutDirectionRightToLeft = NSUserInterfaceLayoutDirectionRightToLeft,
};

typedef NS_ENUM(NSInteger, UIUserInterfaceStyle) {
  UIUserInterfaceStyleUnspecified = 0,
  UIUserInterfaceStyleLight = 1,
  UIUserInterfaceStyleDark = 2,
};

typedef NS_ENUM(NSInteger, UIUserInterfaceSizeClass) {
  UIUserInterfaceSizeClassUnspecified = 0,
  UIUserInterfaceSizeClassCompact = 1,
  UIUserInterfaceSizeClassRegular = 2,
};

typedef NS_ENUM(NSInteger, UIScrollViewContentInsetAdjustmentBehavior) {
  UIScrollViewContentInsetAdjustmentAutomatic = 0,
  UIScrollViewContentInsetAdjustmentScrollableAxes,
  UIScrollViewContentInsetAdjustmentNever,
  UIScrollViewContentInsetAdjustmentAlways,
};

typedef NS_ENUM(NSInteger, UITextSmartInsertDeleteType) {
  UITextSmartInsertDeleteTypeDefault = 0,
  UITextSmartInsertDeleteTypeNo,
  UITextSmartInsertDeleteTypeYes,
};

typedef NS_ENUM(NSInteger, UITextSmartQuotesType) {
  UITextSmartQuotesTypeDefault = 0,
  UITextSmartQuotesTypeNo,
  UITextSmartQuotesTypeYes,
};

typedef NS_ENUM(NSInteger, UITextSmartDashesType) {
  UITextSmartDashesTypeDefault = 0,
  UITextSmartDashesTypeNo,
  UITextSmartDashesTypeYes,
};

@protocol UIMenuBuilder <NSObject>
@end

typedef NS_ENUM(NSInteger, UIStatusBarStyle) {
  UIStatusBarStyleDefault = 0,
  UIStatusBarStyleLightContent = 1,
  UIStatusBarStyleDarkContent = 3,
};

typedef NS_OPTIONS(NSUInteger, UIInterfaceOrientationMask) {
  UIInterfaceOrientationMaskPortrait = 1 << 1,
  UIInterfaceOrientationMaskLandscapeLeft = 1 << 4,
  UIInterfaceOrientationMaskLandscapeRight = 1 << 3,
  UIInterfaceOrientationMaskPortraitUpsideDown = 1 << 2,
  UIInterfaceOrientationMaskLandscape = (1 << 3) | (1 << 4),
  UIInterfaceOrientationMaskAllButUpsideDown = 0,
  UIInterfaceOrientationMaskAll = 0,
};

typedef NS_ENUM(NSInteger, UIKeyboardType) {
  UIKeyboardTypeDefault = 0,
  UIKeyboardTypeASCIICapable,
  UIKeyboardTypeNumbersAndPunctuation,
  UIKeyboardTypeURL,
  UIKeyboardTypeNumberPad,
  UIKeyboardTypePhonePad,
  UIKeyboardTypeNamePhonePad,
  UIKeyboardTypeEmailAddress,
  UIKeyboardTypeDecimalPad,
  UIKeyboardTypeTwitter,
  UIKeyboardTypeWebSearch,
  UIKeyboardTypeASCIICapableNumberPad,
};

typedef NS_ENUM(NSInteger, UIReturnKeyType) {
  UIReturnKeyDefault = 0,
  UIReturnKeyGo,
  UIReturnKeyGoogle,
  UIReturnKeyJoin,
  UIReturnKeyNext,
  UIReturnKeyRoute,
  UIReturnKeySearch,
  UIReturnKeySend,
  UIReturnKeyYahoo,
  UIReturnKeyDone,
  UIReturnKeyEmergencyCall,
  UIReturnKeyContinue,
};

typedef NS_ENUM(NSInteger, UITextFieldViewMode) {
  UITextFieldViewModeNever = 0,
  UITextFieldViewModeWhileEditing,
  UITextFieldViewModeUnlessEditing,
  UITextFieldViewModeAlways,
};

typedef NS_OPTIONS(NSUInteger, UIDataDetectorTypes) {
  UIDataDetectorTypeNone = 0,
  UIDataDetectorTypePhoneNumber = 1 << 0,
  UIDataDetectorTypeLink = 1 << 1,
  UIDataDetectorTypeAddress = 1 << 2,
  UIDataDetectorTypeCalendarEvent = 1 << 3,
  UIDataDetectorTypeShipmentTrackingNumber = 1 << 4,
  UIDataDetectorTypeFlightNumber = 1 << 5,
  UIDataDetectorTypeLookupSuggestion = 1 << 6,
  UIDataDetectorTypeMoney = 1 << 7,
  UIDataDetectorTypePhysicalValue = 1 << 8,
  UIDataDetectorTypeAll = NSUIntegerMax,
};

typedef NS_OPTIONS(NSUInteger, UIControlState) {
  UIControlStateNormal = 0,
  UIControlStateHighlighted = 1 << 0,
  UIControlStateDisabled = 1 << 1,
  UIControlStateSelected = 1 << 2,
};

typedef NS_OPTIONS(NSUInteger, UIControlEvents) {
  UIControlEventTouchDown = 1 << 0,
  UIControlEventTouchUpInside = 1 << 6,
  UIControlEventValueChanged = 1 << 12,
};

typedef NS_ENUM(NSInteger, UIModalPresentationStyle) {
  UIModalPresentationFullScreen = 0,
  UIModalPresentationPageSheet = 1,
  UIModalPresentationFormSheet = 2,
  UIModalPresentationOverFullScreen = 5,
};

#define UIKeyModifierCommand NSEventModifierFlagCommand
#define UIKeyModifierShift NSEventModifierFlagShift
#define UIKeyModifierControl NSEventModifierFlagControl
#define UIKeyModifierAlternate NSEventModifierFlagOption
#define UIKeyModifierAlphaShift NSEventModifierFlagCapsLock

NS_ASSUME_NONNULL_END
