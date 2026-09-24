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

static const UIAccessibilityTraits UIAccessibilityTraitNone = 0;
static const UIAccessibilityTraits UIAccessibilityTraitButton = 1 << 0;
static const UIAccessibilityTraits UIAccessibilityTraitLink = 1 << 1;
static const UIAccessibilityTraits UIAccessibilityTraitImage = 1 << 2;
static const UIAccessibilityTraits UIAccessibilityTraitSelected = 1 << 3;
static const UIAccessibilityTraits UIAccessibilityTraitPlaysSound = 1 << 4;
static const UIAccessibilityTraits UIAccessibilityTraitKeyboardKey = 1 << 5;
static const UIAccessibilityTraits UIAccessibilityTraitStaticText = 1 << 6;
static const UIAccessibilityTraits UIAccessibilityTraitSummaryElement = 1 << 7;
static const UIAccessibilityTraits UIAccessibilityTraitNotEnabled = 1 << 8;
static const UIAccessibilityTraits UIAccessibilityTraitUpdatesFrequently = 1 << 9;
static const UIAccessibilityTraits UIAccessibilityTraitSearchField = 1 << 10;
static const UIAccessibilityTraits UIAccessibilityTraitStartsMediaSession = 1 << 11;
static const UIAccessibilityTraits UIAccessibilityTraitAdjustable = 1 << 12;
static const UIAccessibilityTraits UIAccessibilityTraitAllowsDirectInteraction = 1 << 13;
static const UIAccessibilityTraits UIAccessibilityTraitCausesPageTurn = 1 << 14;
static const UIAccessibilityTraits UIAccessibilityTraitHeader = 1 << 16;
static const UIAccessibilityTraits UIAccessibilityTraitTabBar = 1 << 21;
static const UIAccessibilityTraits UIAccessibilityTraitSwitch = 0x20000000000001;

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
