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

// The shim's compile-time names, which is all this layer is for.
//
// Deliberately aliases rather than real classes: registering a UIKit name
// with the ObjC runtime makes Apple's own frameworks mistake the process for
// Catalyst. macOS's one-time-code AutoFill does exactly that for the focused
// text field, and answering yes sends it into UIKitMacHelper, which dlopens a
// UIKit.framework that does not exist here and takes the process down.
//
// Forward-declared first so the aliases can appear before anything uses them.
@class RCTUIKitCompatAlertAction;
@class RCTUIKitCompatAlertController;
@class RCTUIKitCompatActivityViewController;
@compatibility_alias UIAlertAction RCTUIKitCompatAlertAction;
@compatibility_alias UIAlertController RCTUIKitCompatAlertController;
@compatibility_alias UIActivityViewController RCTUIKitCompatActivityViewController;


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

@interface RCTUIKitCompatAlertAction : NSObject
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
@interface RCTUIKitCompatAlertController : NSViewController

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

typedef NSString *UIActivityType NS_TYPED_ENUM;

/**
 * The share sheet, over NSSharingServicePicker.
 *
 * UIKit presents it as a view controller; AppKit shows a picker anchored to a
 * view. The UIKit shape is kept so upstream's presentation code compiles, and
 * -presentFromView: does the AppKit thing.
 */
@interface RCTUIKitCompatActivityViewController : NSViewController

@property (nonatomic, copy, nullable) void (^completionWithItemsHandler)
    (UIActivityType _Nullable activityType, BOOL completed, NSArray *_Nullable items, NSError *_Nullable error);

@property (nonatomic, copy, nullable) NSArray<UIActivityType> *excludedActivityTypes;

- (instancetype)initWithActivityItems:(NSArray *)activityItems
                applicationActivities:(nullable NSArray *)applicationActivities;

- (void)presentFromView:(NSView *)view;

@end

NS_ASSUME_NONNULL_END
