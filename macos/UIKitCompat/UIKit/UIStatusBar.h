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

typedef NS_ENUM(NSInteger, UIStatusBarAnimation) {
  UIStatusBarAnimationNone = 0,
  UIStatusBarAnimationFade,
  UIStatusBarAnimationSlide,
};

/**
 * macOS has no status bar. The menu bar is the closest thing and it is not
 * per-window, not per-app-controllable, and has no style.
 *
 * This type exists because RCTUtils.h declares a UIStatusBarManager * in its
 * public interface, and almost every React Native source file imports
 * RCTUtils.h. Without it, 86 of 251 sources fail to parse -- half of every
 * failure in the tree traced back to this one missing name.
 *
 * statusBarFrame reports zero height, which is the truthful answer: there is no
 * status bar occluding your content on macOS.
 */
@interface UIStatusBarManager : NSObject

@property (nonatomic, readonly) CGRect statusBarFrame;
@property (nonatomic, readonly) UIStatusBarStyle statusBarStyle;
@property (nonatomic, readonly, getter=isStatusBarHidden) BOOL statusBarHidden;

@end

NS_ASSUME_NONNULL_END
