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

/**
 * A key binding, described the UIKit way.
 *
 * AppKit has no single equivalent. Menu items carry key equivalents, and
 * everything else goes through -performKeyEquivalent: or the responder chain.
 * This is a value object that records the binding so React Native's key
 * command registry compiles and can be replayed against NSEvent.
 */
@interface UIKeyCommand : NSObject

@property (nonatomic, readonly, copy, nullable) NSString *input;
@property (nonatomic, readonly) UIKeyModifierFlags modifierFlags;
@property (nonatomic, readonly, nullable) SEL action;
@property (nonatomic, copy, nullable) NSString *discoverabilityTitle;

+ (instancetype)keyCommandWithInput:(NSString *)input
                      modifierFlags:(UIKeyModifierFlags)modifierFlags
                             action:(nullable SEL)action;

// Does this command match a key-down NSEvent?
- (BOOL)matchesEvent:(NSEvent *)event;

@end

// UIKit hands these to -[UIResponder keyCommands] holders on iPad hardware
// keyboards. There is no macOS analogue; declared so the property type
// resolves.
@interface UIBarButtonItemGroup : NSObject
@end

@interface UITextInputPasswordRules : NSObject
@property (nonatomic, readonly, copy) NSString *passwordRulesDescriptor;
+ (instancetype)passwordRulesWithDescriptor:(NSString *)descriptor;
@end

typedef NS_ENUM(NSInteger, UITextDropEditability) {
  UITextDropEditabilityNo = 0,
  UITextDropEditabilityTemporary,
  UITextDropEditabilityYes,
};

@protocol UITextDropDelegate <NSObject>
@optional
- (BOOL)textDroppableView:(id)view willBecomeEditableForDrop:(id)drop;
@end

@protocol UITextDroppable <NSObject>
@end

@protocol UITextDropRequest <NSObject>
@end

@protocol UIAdaptivePresentationControllerDelegate <NSObject>
@optional
- (void)presentationControllerDidDismiss:(id)presentationController;
@end

NS_ASSUME_NONNULL_END
