/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIAccessibility.h"

#import <objc/runtime.h>

// Storage lives in associated objects because a category cannot add ivars.
// NSView and other NSAccessibility adopters override these with the real thing;
// this only has to serve plain NSObjects.
#define UIKIT_COMPAT_A11Y_OBJECT(type, name, setter)                                              \
  -(type)name                                                                                     \
  {                                                                                               \
    return objc_getAssociatedObject(self, @selector(name));                                       \
  }                                                                                               \
  -(void)setter : (type)value                                                                     \
  {                                                                                               \
    objc_setAssociatedObject(self, @selector(name), value, OBJC_ASSOCIATION_COPY_NONATOMIC);      \
  }

NSString *const UIAccessibilityAnnouncementKeyStringValue = @"UIAccessibilityAnnouncementKeyStringValue";
NSString *const UIAccessibilityAnnouncementKeyWasSuccessful = @"UIAccessibilityAnnouncementKeyWasSuccessful";

@implementation NSObject (UIKitCompatAccessibility)

- (BOOL)accessibilityViewIsModal
{
  return [objc_getAssociatedObject(self, @selector(accessibilityViewIsModal)) boolValue];
}

- (void)setAccessibilityViewIsModal:(BOOL)value
{
  objc_setAssociatedObject(self, @selector(accessibilityViewIsModal), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)accessibilityRespondsToUserInteraction
{
  return [objc_getAssociatedObject(self, @selector(accessibilityRespondsToUserInteraction)) boolValue];
}

- (void)setAccessibilityRespondsToUserInteraction:(BOOL)value
{
  objc_setAssociatedObject(
      self, @selector(accessibilityRespondsToUserInteraction), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)accessibilityElementsHidden
{
  return [objc_getAssociatedObject(self, @selector(accessibilityElementsHidden)) boolValue];
}

- (void)setAccessibilityElementsHidden:(BOOL)value
{
  objc_setAssociatedObject(self, @selector(accessibilityElementsHidden), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isAccessibilityElement
{
  return [objc_getAssociatedObject(self, @selector(isAccessibilityElement)) boolValue];
}

- (void)setIsAccessibilityElement:(BOOL)value
{
  objc_setAssociatedObject(self, @selector(isAccessibilityElement), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

UIKIT_COMPAT_A11Y_OBJECT(NSString *, accessibilityLabel, setAccessibilityLabel)
UIKIT_COMPAT_A11Y_OBJECT(NSString *, accessibilityHint, setAccessibilityHint)
UIKIT_COMPAT_A11Y_OBJECT(NSString *, accessibilityValue, setAccessibilityValue)
UIKIT_COMPAT_A11Y_OBJECT(NSString *, accessibilityLanguage, setAccessibilityLanguage)
UIKIT_COMPAT_A11Y_OBJECT(NSString *, accessibilityIdentifier, setAccessibilityIdentifier)
UIKIT_COMPAT_A11Y_OBJECT(NSArray *, accessibilityCustomActions, setAccessibilityCustomActions)

- (UIAccessibilityTraits)accessibilityTraits
{
  return (UIAccessibilityTraits)[objc_getAssociatedObject(self, @selector(accessibilityTraits)) unsignedLongLongValue];
}

- (void)setAccessibilityTraits:(UIAccessibilityTraits)traits
{
  objc_setAssociatedObject(self, @selector(accessibilityTraits), @(traits), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGRect)accessibilityFrame
{
  NSValue *stored = objc_getAssociatedObject(self, @selector(accessibilityFrame));
  return stored == nil ? CGRectZero : NSRectToCGRect(stored.rectValue);
}

- (void)setAccessibilityFrame:(CGRect)frame
{
  objc_setAssociatedObject(
      self,
      @selector(accessibilityFrame),
      [NSValue valueWithRect:NSRectFromCGRect(frame)],
      OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
