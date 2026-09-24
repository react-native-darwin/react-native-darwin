/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIKitDefines.h"

NS_ASSUME_NONNULL_BEGIN

@compatibility_alias UIApplication NSApplication;

// UIKit's app states. macOS has no true background or inactive-then-suspended
// cycle, so only Active and Inactive ever occur in practice.
typedef NS_ENUM(NSInteger, UIApplicationState) {
  UIApplicationStateActive = 0,
  UIApplicationStateInactive = 1,
  UIApplicationStateBackground = 2,
};

@interface NSApplication (UIKitCompat)

@property (nonatomic, readonly) UIApplicationState applicationState;

// UIKit calls it sharedApplication; AppKit calls it sharedApplication too, so
// nothing is needed there. These are the genuinely missing pieces.
@property (nonatomic, readonly, nullable) NSWindow *keyWindowForUIKitCompat;

- (BOOL)openURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
