/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIKitDefines.h"

// The shim's compile-time names, which is all this layer is for.
//
// Deliberately aliases rather than real classes: registering a UIKit name
// with the ObjC runtime makes Apple's own frameworks mistake the process for
// Catalyst. macOS's one-time-code AutoFill does exactly that for the focused
// text field, and answering yes sends it into UIKitMacHelper, which dlopens a
// UIKit.framework that does not exist here and takes the process down.
//
// Forward-declared first so the aliases can appear before anything uses them.
@class RCTUIKitCompatEditMenuConfiguration;
@class RCTUIKitCompatEditMenuInteraction;
@class RCTUIKitCompatMenuController;
@class RCTUIKitCompatPresentationController;
@compatibility_alias UIEditMenuConfiguration RCTUIKitCompatEditMenuConfiguration;
@compatibility_alias UIEditMenuInteraction RCTUIKitCompatEditMenuInteraction;
@compatibility_alias UIMenuController RCTUIKitCompatMenuController;
@compatibility_alias UIPresentationController RCTUIKitCompatPresentationController;


NS_ASSUME_NONNULL_BEGIN

enum {
  UIViewAnimationCurveEaseInOut = 0,
  UIViewAnimationCurveEaseIn = 1,
  UIViewAnimationCurveEaseOut = 2,
  UIViewAnimationCurveLinear = 3,
};

typedef NS_OPTIONS(NSUInteger, UIViewAnimationOptions) {
  UIViewAnimationOptionLayoutSubviews = 1 << 0,
  UIViewAnimationOptionAllowUserInteraction = 1 << 1,
  UIViewAnimationOptionBeginFromCurrentState = 1 << 2,
  UIViewAnimationOptionRepeat = 1 << 3,
  UIViewAnimationOptionAutoreverse = 1 << 4,
  UIViewAnimationOptionOverrideInheritedDuration = 1 << 5,
  UIViewAnimationOptionOverrideInheritedCurve = 1 << 6,
  UIViewAnimationOptionAllowAnimatedContent = 1 << 7,
  UIViewAnimationOptionShowHideTransitionViews = 1 << 8,
  UIViewAnimationOptionCurveEaseInOut = 0 << 16,
  UIViewAnimationOptionCurveEaseIn = 1 << 16,
  UIViewAnimationOptionCurveEaseOut = 2 << 16,
  UIViewAnimationOptionCurveLinear = 3 << 16,
};

typedef NS_ENUM(NSInteger, UIModalTransitionStyle) {
  UIModalTransitionStyleCoverVertical = 0,
  UIModalTransitionStyleFlipHorizontal,
  UIModalTransitionStyleCrossDissolve,
  UIModalTransitionStylePartialCurl,
};

// AppKit's stack view is close enough in role to alias.
@compatibility_alias UIStackView NSStackView;

typedef NSString *UITextContentType NS_TYPED_ENUM;
extern UITextContentType const UITextContentTypeURL;
extern UITextContentType const UITextContentTypeEmailAddress;
extern UITextContentType const UITextContentTypeTelephoneNumber;
extern UITextContentType const UITextContentTypeName;
extern UITextContentType const UITextContentTypeUsername;
extern UITextContentType const UITextContentTypePassword;
extern UITextContentType const UITextContentTypeNewPassword;
extern UITextContentType const UITextContentTypeOneTimeCode;
extern UITextContentType const UITextContentTypeFullStreetAddress;
extern UITextContentType const UITextContentTypePostalCode;
extern UITextContentType const UITextContentTypeCreditCardNumber;
extern UITextContentType const UITextContentTypeAddressCity;
extern UITextContentType const UITextContentTypeAddressState;
extern UITextContentType const UITextContentTypeAddressCityAndState;
extern UITextContentType const UITextContentTypeCountryName;
extern UITextContentType const UITextContentTypeStreetAddressLine1;
extern UITextContentType const UITextContentTypeStreetAddressLine2;
extern UITextContentType const UITextContentTypeSublocality;
extern UITextContentType const UITextContentTypeGivenName;
extern UITextContentType const UITextContentTypeMiddleName;
extern UITextContentType const UITextContentTypeFamilyName;
extern UITextContentType const UITextContentTypeNamePrefix;
extern UITextContentType const UITextContentTypeNameSuffix;
extern UITextContentType const UITextContentTypeNickname;
extern UITextContentType const UITextContentTypeJobTitle;
extern UITextContentType const UITextContentTypeOrganizationName;
extern UITextContentType const UITextContentTypeLocation;
extern UITextContentType const UITextContentTypeDateTime;
extern UITextContentType const UITextContentTypeFlightNumber;
extern UITextContentType const UITextContentTypeShipmentTrackingNumber;
extern UITextContentType const UITextContentTypeCreditCardExpiration;
extern UITextContentType const UITextContentTypeCreditCardSecurityCode;
extern UITextContentType const UITextContentTypeCellularEID;
extern UITextContentType const UITextContentTypeCellularIMEI;

// NSStackView already declares -distribution and -alignment with its own types,
// and a category cannot narrow a property's type. So rather than invent parallel
// enums, these are the AppKit types with UIKit's spellings -- assignment then
// type-checks without touching NSStackView at all.
typedef NSStackViewDistribution UIStackViewDistribution;

static const UIStackViewDistribution UIStackViewDistributionFill = NSStackViewDistributionFill;
static const UIStackViewDistribution UIStackViewDistributionFillEqually = NSStackViewDistributionFillEqually;
static const UIStackViewDistribution UIStackViewDistributionFillProportionally = NSStackViewDistributionFillProportionally;
static const UIStackViewDistribution UIStackViewDistributionEqualSpacing = NSStackViewDistributionEqualSpacing;
static const UIStackViewDistribution UIStackViewDistributionEqualCentering = NSStackViewDistributionEqualCentering;

typedef NSLayoutAttribute UIStackViewAlignment;

// UIKit's Fill means "no cross-axis alignment constraint", which AppKit spells
// as no attribute at all.
static const UIStackViewAlignment UIStackViewAlignmentFill = NSLayoutAttributeNotAnAttribute;
static const UIStackViewAlignment UIStackViewAlignmentLeading = NSLayoutAttributeLeading;
static const UIStackViewAlignment UIStackViewAlignmentCenter = NSLayoutAttributeCenterX;
static const UIStackViewAlignment UIStackViewAlignmentTrailing = NSLayoutAttributeTrailing;
static const UIStackViewAlignment UIStackViewAlignmentTop = NSLayoutAttributeTop;
static const UIStackViewAlignment UIStackViewAlignmentBottom = NSLayoutAttributeBottom;
static const UIStackViewAlignment UIStackViewAlignmentFirstBaseline = NSLayoutAttributeFirstBaseline;
static const UIStackViewAlignment UIStackViewAlignmentLastBaseline = NSLayoutAttributeLastBaseline;

// UIKit names its layout guide type; AppKit's is NSLayoutGuide.
@compatibility_alias UILayoutGuide NSLayoutGuide;

// Hardware key strings UIKit exposes for key commands.
extern NSString *const UIKeyInputEscape;
extern NSString *const UIKeyInputUpArrow;
extern NSString *const UIKeyInputDownArrow;
extern NSString *const UIKeyInputLeftArrow;
extern NSString *const UIKeyInputRightArrow;

typedef NS_ENUM(NSInteger, UIScrollViewIndicatorStyle) {
  UIScrollViewIndicatorStyleDefault = 0,
  UIScrollViewIndicatorStyleBlack,
  UIScrollViewIndicatorStyleWhite,
};

typedef NS_ENUM(NSInteger, UIScrollViewKeyboardDismissMode) {
  UIScrollViewKeyboardDismissModeNone = 0,
  UIScrollViewKeyboardDismissModeOnDrag,
  UIScrollViewKeyboardDismissModeInteractive,
};

/**
 * The text selection edit menu.
 *
 * iOS 16 models this as an interaction plus a configuration; earlier iOS used
 * the UIMenuController singleton. AppKit has neither -- a text view shows its
 * own contextual NSMenu. Both shapes are declared so the paragraph component
 * compiles; presenting is a no-op because AppKit already does it.
 */
@interface RCTUIKitCompatEditMenuConfiguration : NSObject
@property (nonatomic, readonly) CGPoint sourcePoint;
@property (nonatomic, strong, nullable) id background;
@property (nonatomic, assign) UIEdgeInsets contentInsets;
@property (nonatomic, strong, nullable) NSColor *baseForegroundColor;
+ (instancetype)configurationWithIdentifier:(nullable id)identifier sourcePoint:(CGPoint)sourcePoint;
@end

@interface RCTUIKitCompatEditMenuInteraction : NSObject
- (instancetype)initWithDelegate:(nullable id)delegate;
- (void)presentEditMenuWithConfiguration:(UIEditMenuConfiguration *)configuration;
- (void)dismissMenu;
@end

@interface RCTUIKitCompatMenuController : NSObject
@property (class, nonatomic, readonly) UIMenuController *sharedMenuController;
@property (nonatomic, readonly, getter=isMenuVisible) BOOL menuVisible;
- (void)showMenuFromView:(NSView *)view rect:(CGRect)rect;
- (void)hideMenu;
@end

@interface NSResponder (UIKitCompatEditActions)
// UIResponder's gate for the edit menu. NSResponder uses
// -validateUserInterfaceItem:, so this answers from the selector alone.
- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender;
@end

@interface NSPasteboard (UIKitCompatItems)
// UIPasteboard.items is a read-write array of type->value dictionaries.
// Writing it replaces the pasteboard contents, which is what -clearContents
// plus a write does on AppKit.
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *items;
@end

typedef NS_ENUM(NSInteger, UILayoutConstraintAxis) {
  UILayoutConstraintAxisHorizontal = 0,
  UILayoutConstraintAxisVertical = 1,
};

// Presentation controllers have no AppKit counterpart; sheets and popovers are
// managed by the presenting controller itself.
typedef NS_OPTIONS(NSUInteger, UIPopoverArrowDirection) {
  UIPopoverArrowDirectionUp = 1 << 0,
  UIPopoverArrowDirectionDown = 1 << 1,
  UIPopoverArrowDirectionLeft = 1 << 2,
  UIPopoverArrowDirectionRight = 1 << 3,
  UIPopoverArrowDirectionAny = 0x0f,
  UIPopoverArrowDirectionUnknown = NSUIntegerMax,
};

/**
 * UIKit's presentation controller, with the popover fields upstream anchors
 * action sheets and share sheets to.
 *
 * AppKit anchors an NSPopover or an NSSharingServicePicker to a view and a
 * rect directly, so these are recorded and read back by the presenting code
 * rather than driving a controller of their own.
 */
@interface RCTUIKitCompatPresentationController : NSObject
@property (nonatomic, readonly, nullable) NSViewController *presentedViewController;
@property (nonatomic, weak, nullable) id delegate;
@property (nonatomic, weak, nullable) NSView *sourceView;
@property (nonatomic, assign) CGRect sourceRect;
@property (nonatomic, assign) UIPopoverArrowDirection permittedArrowDirections;
@property (nonatomic, strong, nullable) id barButtonItem;
@end

@interface NSView (UIKitCompatInteraction)
// UIInteraction has no AppKit analogue; the calls are accepted and dropped.
- (void)addInteraction:(id)interaction;
- (void)removeInteraction:(id)interaction;
- (NSInteger)accessibilityElementCount;
@end

@interface NSViewController (UIKitCompatContainment)
- (void)didMoveToParentViewController:(nullable NSViewController *)parent;
- (void)willMoveToParentViewController:(nullable NSViewController *)parent;
// NSViewController already has -removeFromParentViewController.
@end

@interface NSWindow (UIKitCompatFrame)
// NSWindow.frame is read-only; UIWindow's is settable.
- (void)setFrame:(CGRect)frame;
@end

// Dynamic Type has no macOS equivalent; the category is always Large.
typedef NSString *UIContentSizeCategory NS_TYPED_ENUM;
extern UIContentSizeCategory const UIContentSizeCategoryExtraSmall;
extern UIContentSizeCategory const UIContentSizeCategorySmall;
extern UIContentSizeCategory const UIContentSizeCategoryMedium;
extern UIContentSizeCategory const UIContentSizeCategoryLarge;
extern UIContentSizeCategory const UIContentSizeCategoryExtraLarge;
extern UIContentSizeCategory const UIContentSizeCategoryExtraExtraLarge;
extern UIContentSizeCategory const UIContentSizeCategoryExtraExtraExtraLarge;
extern UIContentSizeCategory const UIContentSizeCategoryAccessibilityMedium;
extern UIContentSizeCategory const UIContentSizeCategoryAccessibilityLarge;
extern UIContentSizeCategory const UIContentSizeCategoryAccessibilityExtraLarge;
extern UIContentSizeCategory const UIContentSizeCategoryAccessibilityExtraExtraLarge;
extern UIContentSizeCategory const UIContentSizeCategoryAccessibilityExtraExtraExtraLarge;

@interface NSApplication (UIKitCompatContentSize)
@property (nonatomic, readonly, copy) UIContentSizeCategory preferredContentSizeCategory;
@end

@interface NSView (UIKitCompatContentSize)
@property (nonatomic, readonly, copy) UIContentSizeCategory preferredContentSizeCategory;
@end

// VoiceOver announcement attributes. AppKit expresses priority as an
// NSAccessibilityPriorityLevel in the notification's user info.
typedef NSString *UIAccessibilitySpeechAttribute NS_TYPED_ENUM;
extern UIAccessibilitySpeechAttribute const UIAccessibilitySpeechAttributeQueueAnnouncement;
extern UIAccessibilitySpeechAttribute const UIAccessibilitySpeechAttributeAnnouncementPriority;

typedef NSString *UIAccessibilityPriority NS_TYPED_ENUM;
extern UIAccessibilityPriority const UIAccessibilityPriorityLow;
extern UIAccessibilityPriority const UIAccessibilityPriorityDefault;
extern UIAccessibilityPriority const UIAccessibilityPriorityHigh;

extern NSNotificationName const UIDeviceProximityStateDidChangeNotification;
extern NSNotificationName const UIDeviceBatteryLevelDidChangeNotification;
extern NSNotificationName const UIDeviceOrientationDidChangeNotification;

@interface NSStackView (UIKitCompat)
- (instancetype)initWithArrangedSubviews:(NSArray<NSView *> *)views;
@end

@interface NSApplication (UIKitCompatCanOpen)
- (BOOL)canOpenURL:(NSURL *)url;
@end

/**
 * UIKit's animation entry points, over NSAnimationContext.
 *
 * Spring parameters are dropped: AppKit has no spring timing in this API, and
 * pretending otherwise would animate at the wrong rate rather than fail
 * visibly.
 */
@interface RCTPlatformViewAnimator : NSObject
@end

@interface NSView (UIKitCompatAnimation)
+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations;
+ (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(void (^)(void))animations
                 completion:(void (^_Nullable)(BOOL finished))completion;
+ (void)animateWithDuration:(NSTimeInterval)duration
                      delay:(NSTimeInterval)delay
                    options:(UIViewAnimationOptions)options
                 animations:(void (^)(void))animations
                 completion:(void (^_Nullable)(BOOL finished))completion;
+ (void)animateWithDuration:(NSTimeInterval)duration
                      delay:(NSTimeInterval)delay
     usingSpringWithDamping:(CGFloat)dampingRatio
      initialSpringVelocity:(CGFloat)velocity
                    options:(UIViewAnimationOptions)options
                 animations:(void (^)(void))animations
                 completion:(void (^_Nullable)(BOOL finished))completion;
+ (NSUserInterfaceLayoutDirection)userInterfaceLayoutDirectionForSemanticContentAttribute:(NSInteger)attribute;
@end

@protocol UIUserActivityRestoring <NSObject>
@optional
- (void)restoreUserActivityState:(NSUserActivity *)activity;
@end

#ifdef __cplusplus
extern "C" {
#endif

// UIKit's image encoders. CoreGraphics does the work on macOS.
NSData *_Nullable UIImagePNGRepresentation(NSImage *image);
NSData *_Nullable UIImageJPEGRepresentation(NSImage *image, CGFloat compressionQuality);

// UIKit posts accessibility notifications through a function rather than
// NSNotificationCenter. Routed to NSAccessibility where an equivalent exists.
void UIAccessibilityPostNotification(NSNotificationName notification, id _Nullable argument);
BOOL UIAccessibilityIsVoiceOverRunning(void);
BOOL UIAccessibilityIsReduceMotionEnabled(void);
BOOL UIAccessibilityIsReduceTransparencyEnabled(void);
BOOL UIAccessibilityIsInvertColorsEnabled(void);
BOOL UIAccessibilityIsBoldTextEnabled(void);
BOOL UIAccessibilityIsGrayscaleEnabled(void);
BOOL UIAccessibilityDarkerSystemColorsEnabled(void);
BOOL UIAccessibilityIsSwitchControlRunning(void);
// The rest of UIKit's accessibility queries. Only the handful AppKit actually
// tracks return anything but NO -- see the implementation for which.
BOOL UIAccessibilityPrefersCrossFadeTransitions(void);
BOOL UIAccessibilityIsVideoAutoplayEnabled(void);
BOOL UIAccessibilityShouldDifferentiateWithoutColor(void);
BOOL UIAccessibilityIsOnOffSwitchLabelsEnabled(void);
BOOL UIAccessibilityIsClosedCaptioningEnabled(void);
BOOL UIAccessibilityIsMonoAudioEnabled(void);
BOOL UIAccessibilityIsShakeToUndoEnabled(void);
BOOL UIAccessibilityIsGuidedAccessEnabled(void);
BOOL UIAccessibilityIsAssistiveTouchRunning(void);
BOOL UIAccessibilityButtonShapesEnabled(void);
// The element VoiceOver is on. AppKit tracks this per application.
id _Nullable UIAccessibilityFocusedElement(id _Nullable assistiveTechnologyIdentifier);
BOOL UIAccessibilityIsSpeakScreenEnabled(void);
BOOL UIAccessibilityIsSpeakSelectionEnabled(void);

#ifdef __cplusplus
}
#endif

extern NSNotificationName const UIAccessibilityAnnouncementDidFinishNotification;
extern NSNotificationName const UIAccessibilityVoiceOverStatusDidChangeNotification;
extern NSNotificationName const UIAccessibilityReduceMotionStatusDidChangeNotification;
extern NSNotificationName const UIAccessibilityInvertColorsStatusDidChangeNotification;
extern NSNotificationName const UIAccessibilityReduceTransparencyStatusDidChangeNotification;
extern NSNotificationName const UIAccessibilityBoldTextStatusDidChangeNotification;
extern NSNotificationName const UIAccessibilityGrayscaleStatusDidChangeNotification;
extern NSNotificationName const UIAccessibilityDarkerSystemColorsStatusDidChangeNotification;

NS_ASSUME_NONNULL_END
