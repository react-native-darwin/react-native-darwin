/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIAccessibility.h"
#import "UIKitDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * UIKit's trait collection, derived from NSAppearance.
 *
 * Only the traits that mean something on macOS are populated: interface style
 * (light or dark) and accessibility contrast. Size classes are always
 * Unspecified -- a resizable window has no compact or regular notion.
 */
@interface UITraitCollection : NSObject

@property (nonatomic, readonly) UIUserInterfaceStyle userInterfaceStyle;
@property (nonatomic, readonly) UIAccessibilityContrast accessibilityContrast;
@property (nonatomic, readonly) UIUserInterfaceSizeClass horizontalSizeClass;
@property (nonatomic, readonly) UIUserInterfaceSizeClass verticalSizeClass;
@property (nonatomic, readonly) CGFloat displayScale;
// Dynamic Type does not exist on macOS; always Large.
@property (nonatomic, readonly, copy) NSString *preferredContentSizeCategory;
// Force Touch trackpads exist, but AppKit exposes pressure per event rather
// than as a capability, and React Native only reads this to gate 3D Touch.
@property (nonatomic, readonly) NSInteger forceTouchCapability;

+ (UITraitCollection *)currentTraitCollection;
- (BOOL)hasDifferentColorAppearanceComparedToTraitCollection:(nullable UITraitCollection *)other;
+ (UITraitCollection *)traitCollectionWithAppearance:(NSAppearance *)appearance;

// UIKit builds trait collections compositionally. Only the two traits macOS can
// express are carried; everything else stays Unspecified.
+ (UITraitCollection *)traitCollectionWithUserInterfaceStyle:(UIUserInterfaceStyle)style;
+ (UITraitCollection *)traitCollectionWithAccessibilityContrast:(UIAccessibilityContrast)contrast;
+ (UITraitCollection *)traitCollectionWithTraitsFromCollections:(NSArray<UITraitCollection *> *)collections;

@end

@interface NSView (UIKitCompatTraits)
@property (nonatomic, readonly) UITraitCollection *traitCollection;
@end

@interface NSWindow (UIKitCompatTraits)
@property (nonatomic, readonly) UITraitCollection *traitCollection;
@end

NS_ASSUME_NONNULL_END
