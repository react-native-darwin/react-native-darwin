/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIKeyCommand.h"

@implementation UIKeyCommand

+ (instancetype)keyCommandWithInput:(NSString *)input
                      modifierFlags:(UIKeyModifierFlags)modifierFlags
                             action:(SEL)action
{
  UIKeyCommand *command = [UIKeyCommand new];
  command->_input = [input copy];
  command->_modifierFlags = modifierFlags;
  command->_action = action;
  return command;
}

- (BOOL)matchesEvent:(NSEvent *)event
{
  if (event.type != NSEventTypeKeyDown) {
    return NO;
  }

  // Compare only the modifiers a user can press. NSEvent also reports state
  // bits such as NumericPad and Function, which would never match.
  NSEventModifierFlags mask = NSEventModifierFlagCommand | NSEventModifierFlagShift |
      NSEventModifierFlagControl | NSEventModifierFlagOption;
  if ((event.modifierFlags & mask) != (_modifierFlags & mask)) {
    return NO;
  }

  return [event.charactersIgnoringModifiers isEqualToString:_input];
}

@end

@implementation UITextDropProposal

- (instancetype)initWithDropOperation:(UIDropOperation)operation
{
  if ((self = [super init])) {
    _operation = operation;
  }
  return self;
}

@end

@implementation UIBarButtonItemGroup
@end

@implementation UITextInputPasswordRules

+ (instancetype)passwordRulesWithDescriptor:(NSString *)descriptor
{
  UITextInputPasswordRules *rules = [UITextInputPasswordRules new];
  rules->_passwordRulesDescriptor = [descriptor copy];
  return rules;
}

@end
