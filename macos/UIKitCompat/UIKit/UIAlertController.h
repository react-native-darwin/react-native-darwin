/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIKitDefines.h"
#import "UIText.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UIAlertActionStyle) {
  UIAlertActionStyleDefault = 0,
  UIAlertActionStyleCancel,
  UIAlertActionStyleDestructive,
};

typedef NS_ENUM(NSInteger, UIAlertControllerStyle) {
  UIAlertControllerStyleActionSheet = 0,
  UIAlertControllerStyleAlert,
};

@interface UIAlertAction : NSObject
@property (nonatomic, readonly, copy, nullable) NSString *title;
@property (nonatomic, readonly) UIAlertActionStyle style;
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
+ (instancetype)actionWithTitle:(nullable NSString *)title
                          style:(UIAlertActionStyle)style
                        handler:(void (^_Nullable)(UIAlertAction *action))handler;
@end

/**
 * NSAlert wearing a UIAlertController's interface.
 *
 * UIKit presents an alert by pushing a view controller; AppKit runs a modal or
 * a sheet on a window. The shape is preserved -- create, add actions, present
 * -- and -presentFromWindow: does the AppKit thing underneath.
 *
 * Declared as an NSViewController subclass because upstream stores it in
 * UIViewController-typed properties and presents it through the same paths.
 */
@interface UIAlertController : NSViewController

@property (nonatomic, readonly) NSArray<UIAlertAction *> *actions;
@property (nonatomic, assign) UIAlertControllerStyle preferredStyle;
@property (nonatomic, copy, nullable) NSString *message;
@property (nonatomic, strong, nullable) UIAlertAction *preferredAction;

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title
                                 message:(nullable NSString *)message
                          preferredStyle:(UIAlertControllerStyle)preferredStyle;

- (void)addAction:(UIAlertAction *)action;
// NSAlert takes a single accessory view, so the configured fields are stacked
// into one.
- (void)addTextFieldWithConfigurationHandler:(void (^_Nullable)(UITextField *textField))configurationHandler;
@property (nonatomic, readonly, nullable) NSArray<UITextField *> *textFields;

// Runs the alert as a sheet on `window`, or application-modal when nil.
- (void)presentFromWindow:(nullable NSWindow *)window;

@end

NS_ASSUME_NONNULL_END
