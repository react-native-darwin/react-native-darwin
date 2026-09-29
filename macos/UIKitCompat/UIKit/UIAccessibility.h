/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

// UIKit packs accessibility traits into a bitmask. AppKit uses roles and
// subroles instead, with no numeric equivalent. The bit values below are UIKit's
// own, kept so that traits round-trip through the C++ renderer unchanged; the
// mapping onto NSAccessibility happens at the view layer, not here.
typedef uint64_t UIAccessibilityTraits;

// The values live in RCTPlatformTypes.h; these are the UIKit spellings.
#define UIAccessibilityTraitNone RCTPlatformAccessibilityTraitNone
#define UIAccessibilityTraitButton RCTPlatformAccessibilityTraitButton
#define UIAccessibilityTraitLink RCTPlatformAccessibilityTraitLink
#define UIAccessibilityTraitImage RCTPlatformAccessibilityTraitImage
#define UIAccessibilityTraitSelected RCTPlatformAccessibilityTraitSelected
#define UIAccessibilityTraitPlaysSound RCTPlatformAccessibilityTraitPlaysSound
#define UIAccessibilityTraitKeyboardKey RCTPlatformAccessibilityTraitKeyboardKey
#define UIAccessibilityTraitStaticText RCTPlatformAccessibilityTraitStaticText
#define UIAccessibilityTraitSummaryElement RCTPlatformAccessibilityTraitSummaryElement
#define UIAccessibilityTraitNotEnabled RCTPlatformAccessibilityTraitNotEnabled
#define UIAccessibilityTraitUpdatesFrequently RCTPlatformAccessibilityTraitUpdatesFrequently
#define UIAccessibilityTraitSearchField RCTPlatformAccessibilityTraitSearchField
#define UIAccessibilityTraitStartsMediaSession RCTPlatformAccessibilityTraitStartsMediaSession
#define UIAccessibilityTraitAdjustable RCTPlatformAccessibilityTraitAdjustable
#define UIAccessibilityTraitAllowsDirectInteraction RCTPlatformAccessibilityTraitAllowsDirectInteraction
#define UIAccessibilityTraitCausesPageTurn RCTPlatformAccessibilityTraitCausesPageTurn
#define UIAccessibilityTraitHeader RCTPlatformAccessibilityTraitHeader
#define UIAccessibilityTraitTabBar RCTPlatformAccessibilityTraitTabBar
#define UIAccessibilityTraitSwitch RCTPlatformAccessibilityTraitSwitch














extern NSString *const UIAccessibilityAnnouncementKeyStringValue;
extern NSString *const UIAccessibilityAnnouncementKeyWasSuccessful;

typedef NS_ENUM(NSInteger, UIAccessibilityContrast) {
  UIAccessibilityContrastUnspecified = 0,
  UIAccessibilityContrastNormal = 1,
  UIAccessibilityContrastHigh = 2,
};

/**
 * UIKit declares accessibility as an informal protocol on NSObject, so any
 * object can answer -isAccessibilityElement and friends. AppKit's NSAccessibility
 * is a formal protocol adopted by views, which leaves plain NSObjects without
 * the interface. React Native stores accessibility elements as NSObject *, so
 * the informal shape is what it expects.
 */
@interface NSObject (UIKitCompatAccessibility)
@property (nonatomic, assign) BOOL isAccessibilityElement;
@property (nonatomic, copy, nullable) NSString *accessibilityLabel;
@property (nonatomic, copy, nullable) NSString *accessibilityHint;
@property (nonatomic, copy, nullable) NSString *accessibilityValue;
@property (nonatomic, copy, nullable) NSString *accessibilityLanguage;
@property (nonatomic, copy, nullable) NSString *accessibilityIdentifier;
@property (nonatomic, assign) UIAccessibilityTraits accessibilityTraits;
@property (nonatomic, assign) CGRect accessibilityFrame;
@property (nonatomic, copy, nullable) NSArray *accessibilityCustomActions;
@property (nonatomic, assign) BOOL accessibilityViewIsModal;
@property (nonatomic, assign) BOOL accessibilityElementsHidden;
@property (nonatomic, assign) BOOL accessibilityRespondsToUserInteraction;
@end

NS_ASSUME_NONNULL_END
