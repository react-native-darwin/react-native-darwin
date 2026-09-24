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
@class RCTUIKitCompatStatusBarManager;
@compatibility_alias UIStatusBarManager RCTUIKitCompatStatusBarManager;


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
@interface RCTUIKitCompatStatusBarManager : NSObject

@property (nonatomic, readonly) CGRect statusBarFrame;
@property (nonatomic, readonly) UIStatusBarStyle statusBarStyle;
@property (nonatomic, readonly, getter=isStatusBarHidden) BOOL statusBarHidden;

@end

NS_ASSUME_NONNULL_END
