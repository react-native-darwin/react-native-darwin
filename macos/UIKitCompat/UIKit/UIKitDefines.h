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

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

// The shim's compile-time names, which is all this layer is for.
//
// Deliberately aliases rather than real classes: registering a UIKit name
// with the ObjC runtime makes Apple's own frameworks mistake the process for
// Catalyst. macOS's one-time-code AutoFill does exactly that for the focused
// text field, and answering yes sends it into UIKitMacHelper, which dlopens a
// UIKit.framework that does not exist here and takes the process down.
//
// Forward-declared first so the aliases can appear before anything uses them.
@class RCTUIKitCompatScene;
@class RCTUIKitCompatWindowScene;
@compatibility_alias UIScene RCTUIKitCompatScene;
@compatibility_alias UIWindowScene RCTUIKitCompatWindowScene;


NS_ASSUME_NONNULL_BEGIN

#pragma mark - Tier 1: type aliases

// These AppKit types are close enough to their UIKit counterparts that an alias
// is correct. Where a handful of methods are missing, a category supplies them
// rather than a subclass -- a subclass would change the type identity that
// AppKit itself hands back to us.

@compatibility_alias UIFont NSFont;
@compatibility_alias UIFontDescriptor NSFontDescriptor;
@compatibility_alias UIBezierPath NSBezierPath;

@interface NSBezierPath (UIKitCompat)
// UIBezierPath's rounded-rect factory takes one radius; NSBezierPath takes two.
+ (NSBezierPath *)bezierPathWithRoundedRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius;
// UIKit spells -appendBezierPath: as -appendPath:.
- (void)appendPath:(NSBezierPath *)path;
@end
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
typedef NSLayoutPriority UILayoutPriority;

static const UILayoutPriority UILayoutPriorityRequired = NSLayoutPriorityRequired;
static const UILayoutPriority UILayoutPriorityDefaultHigh = NSLayoutPriorityDefaultHigh;
static const UILayoutPriority UILayoutPriorityDefaultLow = NSLayoutPriorityDefaultLow;
static const UILayoutPriority UILayoutPriorityFittingSizeLevel = NSLayoutPriorityFittingSizeCompression;

// Motion events are an iOS-only concept (shake to undo).
typedef NS_ENUM(NSInteger, UIEventSubtype) {
  UIEventSubtypeNone = 0,
  UIEventSubtypeMotionShake = 1,
};
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
typedef NS_ENUM(NSInteger, UISceneActivationState) {
  UISceneActivationStateUnattached = -1,
  UISceneActivationStateForegroundActive = 0,
  UISceneActivationStateForegroundInactive = 1,
  UISceneActivationStateBackground = 2,
};

@interface RCTUIKitCompatScene : NSObject
// A Mac window is either key or it is not; there is no scene lifecycle.
@property (nonatomic, readonly) UISceneActivationState activationState;
@end
@interface RCTUIKitCompatWindowScene : UIScene
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

// The geometry names moved to RCTPlatformTypes.h, the public half. They are
// typedefs, macros and inline functions rather than @compatibility_alias, so
// a library declaring the same ones is not a conflict -- which means they can
// be given to everybody, and libraries written against react-native-macos
// stop needing a macOS-specific spelling for them.

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

// NSGestureRecognizer.state is an NSGestureRecognizerState, and a category
// cannot retype it. So these are that type with UIKit's spellings, which makes
// assignment type-check without touching the AppKit property.
typedef NSGestureRecognizerState UIGestureRecognizerState;

static const UIGestureRecognizerState UIGestureRecognizerStatePossible = NSGestureRecognizerStatePossible;
static const UIGestureRecognizerState UIGestureRecognizerStateBegan = NSGestureRecognizerStateBegan;
static const UIGestureRecognizerState UIGestureRecognizerStateChanged = NSGestureRecognizerStateChanged;
static const UIGestureRecognizerState UIGestureRecognizerStateEnded = NSGestureRecognizerStateEnded;
static const UIGestureRecognizerState UIGestureRecognizerStateCancelled = NSGestureRecognizerStateCancelled;
static const UIGestureRecognizerState UIGestureRecognizerStateFailed = NSGestureRecognizerStateFailed;
static const UIGestureRecognizerState UIGestureRecognizerStateRecognized = NSGestureRecognizerStateRecognized;

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
typedef RCTPlatformViewContentMode UIViewContentMode;
#define UIViewContentModeScaleToFill RCTPlatformViewContentModeScaleToFill
#define UIViewContentModeScaleAspectFit RCTPlatformViewContentModeScaleAspectFit
#define UIViewContentModeScaleAspectFill RCTPlatformViewContentModeScaleAspectFill
#define UIViewContentModeRedraw RCTPlatformViewContentModeRedraw
#define UIViewContentModeCenter RCTPlatformViewContentModeCenter
#define UIViewContentModeTop RCTPlatformViewContentModeTop
#define UIViewContentModeBottom RCTPlatformViewContentModeBottom
#define UIViewContentModeLeft RCTPlatformViewContentModeLeft
#define UIViewContentModeRight RCTPlatformViewContentModeRight
#define UIViewContentModeTopLeft RCTPlatformViewContentModeTopLeft
#define UIViewContentModeTopRight RCTPlatformViewContentModeTopRight
#define UIViewContentModeBottomLeft RCTPlatformViewContentModeBottomLeft
#define UIViewContentModeBottomRight RCTPlatformViewContentModeBottomRight

enum : NSInteger {
  UIUserInterfaceLayoutDirectionLeftToRight = NSUserInterfaceLayoutDirectionLeftToRight,
  UIUserInterfaceLayoutDirectionRightToLeft = NSUserInterfaceLayoutDirectionRightToLeft,
};

typedef RCTPlatformUserInterfaceStyle UIUserInterfaceStyle;
#define UIUserInterfaceStyleUnspecified RCTPlatformUserInterfaceStyleUnspecified
#define UIUserInterfaceStyleLight RCTPlatformUserInterfaceStyleLight
#define UIUserInterfaceStyleDark RCTPlatformUserInterfaceStyleDark

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

typedef RCTPlatformTextSmartInsertDeleteType UITextSmartInsertDeleteType;
#define UITextSmartInsertDeleteTypeDefault RCTPlatformTextSmartInsertDeleteTypeDefault
#define UITextSmartInsertDeleteTypeNo RCTPlatformTextSmartInsertDeleteTypeNo
#define UITextSmartInsertDeleteTypeYes RCTPlatformTextSmartInsertDeleteTypeYes

typedef RCTPlatformTextSmartQuotesType UITextSmartQuotesType;
#define UITextSmartQuotesTypeDefault RCTPlatformTextSmartQuotesTypeDefault
#define UITextSmartQuotesTypeNo RCTPlatformTextSmartQuotesTypeNo
#define UITextSmartQuotesTypeYes RCTPlatformTextSmartQuotesTypeYes

typedef RCTPlatformTextSmartDashesType UITextSmartDashesType;
#define UITextSmartDashesTypeDefault RCTPlatformTextSmartDashesTypeDefault
#define UITextSmartDashesTypeNo RCTPlatformTextSmartDashesTypeNo
#define UITextSmartDashesTypeYes RCTPlatformTextSmartDashesTypeYes

@protocol UIMenuBuilder <NSObject>
@end

typedef RCTPlatformStatusBarStyle UIStatusBarStyle;
#define UIStatusBarStyleDefault RCTPlatformStatusBarStyleDefault
#define UIStatusBarStyleLightContent RCTPlatformStatusBarStyleLightContent
#define UIStatusBarStyleDarkContent RCTPlatformStatusBarStyleDarkContent

typedef RCTPlatformInterfaceOrientationMask UIInterfaceOrientationMask;
#define UIInterfaceOrientationMaskPortrait RCTPlatformInterfaceOrientationMaskPortrait
#define UIInterfaceOrientationMaskLandscapeLeft RCTPlatformInterfaceOrientationMaskLandscapeLeft
#define UIInterfaceOrientationMaskLandscapeRight RCTPlatformInterfaceOrientationMaskLandscapeRight
#define UIInterfaceOrientationMaskPortraitUpsideDown RCTPlatformInterfaceOrientationMaskPortraitUpsideDown
#define UIInterfaceOrientationMaskLandscape RCTPlatformInterfaceOrientationMaskLandscape
#define UIInterfaceOrientationMaskAllButUpsideDown RCTPlatformInterfaceOrientationMaskAllButUpsideDown
#define UIInterfaceOrientationMaskAll RCTPlatformInterfaceOrientationMaskAll

typedef RCTPlatformKeyboardType UIKeyboardType;
#define UIKeyboardTypeDefault RCTPlatformKeyboardTypeDefault
#define UIKeyboardTypeASCIICapable RCTPlatformKeyboardTypeASCIICapable
#define UIKeyboardTypeNumbersAndPunctuation RCTPlatformKeyboardTypeNumbersAndPunctuation
#define UIKeyboardTypeURL RCTPlatformKeyboardTypeURL
#define UIKeyboardTypeNumberPad RCTPlatformKeyboardTypeNumberPad
#define UIKeyboardTypePhonePad RCTPlatformKeyboardTypePhonePad
#define UIKeyboardTypeNamePhonePad RCTPlatformKeyboardTypeNamePhonePad
#define UIKeyboardTypeEmailAddress RCTPlatformKeyboardTypeEmailAddress
#define UIKeyboardTypeDecimalPad RCTPlatformKeyboardTypeDecimalPad
#define UIKeyboardTypeTwitter RCTPlatformKeyboardTypeTwitter
#define UIKeyboardTypeWebSearch RCTPlatformKeyboardTypeWebSearch
#define UIKeyboardTypeASCIICapableNumberPad RCTPlatformKeyboardTypeASCIICapableNumberPad

typedef RCTPlatformReturnKeyType UIReturnKeyType;
#define UIReturnKeyDefault RCTPlatformReturnKeyDefault
#define UIReturnKeyGo RCTPlatformReturnKeyGo
#define UIReturnKeyGoogle RCTPlatformReturnKeyGoogle
#define UIReturnKeyJoin RCTPlatformReturnKeyJoin
#define UIReturnKeyNext RCTPlatformReturnKeyNext
#define UIReturnKeyRoute RCTPlatformReturnKeyRoute
#define UIReturnKeySearch RCTPlatformReturnKeySearch
#define UIReturnKeySend RCTPlatformReturnKeySend
#define UIReturnKeyYahoo RCTPlatformReturnKeyYahoo
#define UIReturnKeyDone RCTPlatformReturnKeyDone
#define UIReturnKeyEmergencyCall RCTPlatformReturnKeyEmergencyCall
#define UIReturnKeyContinue RCTPlatformReturnKeyContinue

typedef RCTPlatformTextFieldViewMode UITextFieldViewMode;
#define UITextFieldViewModeNever RCTPlatformTextFieldViewModeNever
#define UITextFieldViewModeWhileEditing RCTPlatformTextFieldViewModeWhileEditing
#define UITextFieldViewModeUnlessEditing RCTPlatformTextFieldViewModeUnlessEditing
#define UITextFieldViewModeAlways RCTPlatformTextFieldViewModeAlways

typedef RCTPlatformDataDetectorTypes UIDataDetectorTypes;
#define UIDataDetectorTypeNone RCTPlatformDataDetectorTypeNone
#define UIDataDetectorTypePhoneNumber RCTPlatformDataDetectorTypePhoneNumber
#define UIDataDetectorTypeLink RCTPlatformDataDetectorTypeLink
#define UIDataDetectorTypeAddress RCTPlatformDataDetectorTypeAddress
#define UIDataDetectorTypeCalendarEvent RCTPlatformDataDetectorTypeCalendarEvent
#define UIDataDetectorTypeShipmentTrackingNumber RCTPlatformDataDetectorTypeShipmentTrackingNumber
#define UIDataDetectorTypeFlightNumber RCTPlatformDataDetectorTypeFlightNumber
#define UIDataDetectorTypeLookupSuggestion RCTPlatformDataDetectorTypeLookupSuggestion
#define UIDataDetectorTypeMoney RCTPlatformDataDetectorTypeMoney
#define UIDataDetectorTypePhysicalValue RCTPlatformDataDetectorTypePhysicalValue
#define UIDataDetectorTypeAll RCTPlatformDataDetectorTypeAll

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
  UIControlEventEditingDidBegin = 1 << 16,
  UIControlEventEditingChanged = 1 << 17,
  UIControlEventEditingDidEnd = 1 << 18,
  UIControlEventEditingDidEndOnExit = 1 << 19,
  UIControlEventAllEditingEvents = 0x000F0000,
};

typedef RCTPlatformModalPresentationStyle UIModalPresentationStyle;
#define UIModalPresentationFullScreen RCTPlatformModalPresentationFullScreen
#define UIModalPresentationPageSheet RCTPlatformModalPresentationPageSheet
#define UIModalPresentationFormSheet RCTPlatformModalPresentationFormSheet
#define UIModalPresentationOverFullScreen RCTPlatformModalPresentationOverFullScreen
#define UIModalPresentationPopover RCTPlatformModalPresentationPopover

#define UIKeyModifierCommand NSEventModifierFlagCommand
#define UIKeyModifierShift NSEventModifierFlagShift
#define UIKeyModifierControl NSEventModifierFlagControl
#define UIKeyModifierAlternate NSEventModifierFlagOption
#define UIKeyModifierAlphaShift NSEventModifierFlagCapsLock

NS_ASSUME_NONNULL_END
