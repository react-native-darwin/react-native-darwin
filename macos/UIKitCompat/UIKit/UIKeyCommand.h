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
@class RCTUIKitCompatKeyCommand;
@class RCTUIKitCompatBarButtonItemGroup;
@class RCTUIKitCompatTextInputPasswordRules;
@class RCTUIKitCompatTextDropProposal;
@compatibility_alias UIKeyCommand RCTUIKitCompatKeyCommand;
@compatibility_alias UIBarButtonItemGroup RCTUIKitCompatBarButtonItemGroup;
@compatibility_alias UITextInputPasswordRules RCTUIKitCompatTextInputPasswordRules;
@compatibility_alias UITextDropProposal RCTUIKitCompatTextDropProposal;


NS_ASSUME_NONNULL_BEGIN

/**
 * A key binding, described the UIKit way.
 *
 * AppKit has no single equivalent. Menu items carry key equivalents, and
 * everything else goes through -performKeyEquivalent: or the responder chain.
 * This is a value object that records the binding so React Native's key
 * command registry compiles and can be replayed against NSEvent.
 */
@interface RCTUIKitCompatKeyCommand : NSObject

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
@interface RCTUIKitCompatBarButtonItemGroup : NSObject
@end

@interface RCTUIKitCompatTextInputPasswordRules : NSObject
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

typedef NS_ENUM(NSInteger, UIDropOperation) {
  UIDropOperationCancel = 0,
  UIDropOperationForbidden,
  UIDropOperationCopy,
  UIDropOperationMove,
};

// UIKit's text drop machinery. AppKit uses NSDraggingDestination, a different
// model entirely, so these are declared to satisfy the delegate signatures and
// never fire.
@interface RCTUIKitCompatTextDropProposal : NSObject
@property (nonatomic, assign) UIDropOperation operation;
- (instancetype)initWithDropOperation:(UIDropOperation)operation;
@end

// The drag session UIKit hands to a drop delegate.
@protocol UIDropSession <NSObject>
- (BOOL)hasItemsConformingToTypeIdentifiers:(NSArray<NSString *> *)typeIdentifiers;
@end

@protocol UITextDropRequest <NSObject>
@property (nonatomic, readonly, nullable) UITextDropProposal *suggestedProposal;
@property (nonatomic, readonly, nullable) id<UIDropSession> dropSession;
@end

@protocol UIAdaptivePresentationControllerDelegate <NSObject>
@optional
- (void)presentationControllerDidDismiss:(id)presentationController;
@end

NS_ASSUME_NONNULL_END
