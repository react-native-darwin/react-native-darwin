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

// NSColor already answers most of UIColor's interface, including
// +colorWithRed:green:blue:alpha: (10.9+), +colorWithSRGBRed:green:blue:alpha:
// (10.7+) and +colorWithWhite:alpha:, so an alias is correct here. Only the
// genuinely missing pieces are added below.
@compatibility_alias UIColor NSColor;

@interface NSColor (UIKitCompat)

// UIColor exposes -CGColor unconditionally. NSColor's is only valid for colours
// already in an RGB-compatible space, so convert first.
@property (nonatomic, readonly) CGColorRef UIKitCompatCGColor;

// Resolve a dynamic or semantic colour for a specific appearance. The rough
// analogue of -resolvedColorWithTraitCollection: on iOS.
- (NSColor *)resolvedColorWithAppearance:(NSAppearance *)appearance;

// -getRed:green:blue:alpha: raises on NSColor when the receiver is not in an
// RGB space. This variant converts first and returns NO if it cannot.
// UIColor's appearance-aware factory. NSColor's -colorWithName:dynamicProvider:
// is the same idea with a different shape.
+ (NSColor *)colorWithDynamicProvider:(NSColor * (^)(id traitCollection))provider;

// UIKit's semantic colours, mapped to their AppKit counterparts.
@property (class, nonatomic, readonly) NSColor *systemBackgroundColor;
@property (class, nonatomic, readonly) NSColor *secondarySystemBackgroundColor;
@property (class, nonatomic, readonly) NSColor *labelColor2;
@property (class, nonatomic, readonly) NSColor *systemGray6Color;

- (BOOL)UIKitCompatGetRed:(nullable CGFloat *)red
                    green:(nullable CGFloat *)green
                     blue:(nullable CGFloat *)blue
                    alpha:(nullable CGFloat *)alpha;

@end

NS_ASSUME_NONNULL_END
