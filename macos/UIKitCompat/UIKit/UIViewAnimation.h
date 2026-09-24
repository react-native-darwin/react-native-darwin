/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIKitDefines.h"

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

typedef NS_ENUM(NSInteger, UIStackViewDistribution) {
  UIStackViewDistributionFill = 0,
  UIStackViewDistributionFillEqually,
  UIStackViewDistributionFillProportionally,
  UIStackViewDistributionEqualSpacing,
  UIStackViewDistributionEqualCentering,
};

typedef NS_ENUM(NSInteger, UIStackViewAlignment) {
  UIStackViewAlignmentFill = 0,
  UIStackViewAlignmentLeading,
  UIStackViewAlignmentCenter,
  UIStackViewAlignmentTrailing,
};

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

// iOS 16 edit menus. AppKit builds menus from NSMenu.
@interface UIEditMenuInteraction : NSObject
- (instancetype)initWithDelegate:(nullable id)delegate;
@end

@interface NSStackView (UIKitCompatDistribution)
@property (nonatomic, assign) UIStackViewDistribution distributionForUIKitCompat;
@end

typedef NS_ENUM(NSInteger, UILayoutConstraintAxis) {
  UILayoutConstraintAxisHorizontal = 0,
  UILayoutConstraintAxisVertical = 1,
};

// Presentation controllers have no AppKit counterpart; sheets and popovers are
// managed by the presenting controller itself.
@interface UIPresentationController : NSObject
@property (nonatomic, readonly, nullable) NSViewController *presentedViewController;
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
