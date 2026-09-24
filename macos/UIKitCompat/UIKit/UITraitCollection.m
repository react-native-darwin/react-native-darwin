/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UITraitCollection.h"

@implementation UITraitCollection

+ (UITraitCollection *)traitCollectionWithAppearance:(NSAppearance *)appearance
{
  UITraitCollection *traits = [UITraitCollection new];

  NSAppearanceName matched = [appearance bestMatchFromAppearancesWithNames:@[
    NSAppearanceNameAqua,
    NSAppearanceNameDarkAqua,
    NSAppearanceNameAccessibilityHighContrastAqua,
    NSAppearanceNameAccessibilityHighContrastDarkAqua,
  ]];

  BOOL dark = [matched isEqualToString:NSAppearanceNameDarkAqua] ||
      [matched isEqualToString:NSAppearanceNameAccessibilityHighContrastDarkAqua];
  BOOL highContrast = [matched isEqualToString:NSAppearanceNameAccessibilityHighContrastAqua] ||
      [matched isEqualToString:NSAppearanceNameAccessibilityHighContrastDarkAqua];

  traits->_userInterfaceStyle = dark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
  traits->_accessibilityContrast = highContrast ? UIAccessibilityContrastHigh : UIAccessibilityContrastNormal;
  // A resizable window has no compact/regular distinction.
  traits->_horizontalSizeClass = UIUserInterfaceSizeClassUnspecified;
  traits->_verticalSizeClass = UIUserInterfaceSizeClassUnspecified;
  traits->_displayScale = NSScreen.mainScreen.backingScaleFactor ?: 1.0;
  return traits;
}

- (NSString *)preferredContentSizeCategory
{
  return @"UICTContentSizeCategoryL";
}

- (BOOL)hasDifferentColorAppearanceComparedToTraitCollection:(UITraitCollection *)other
{
  if (other == nil) {
    return YES;
  }
  return _userInterfaceStyle != other.userInterfaceStyle ||
      _accessibilityContrast != other.accessibilityContrast;
}

+ (UITraitCollection *)currentTraitCollection
{
  return [self traitCollectionWithAppearance:NSApp.effectiveAppearance ?: NSAppearance.currentDrawingAppearance];
}

@end

@implementation NSView (UIKitCompatTraits)

- (UITraitCollection *)traitCollection
{
  return [UITraitCollection traitCollectionWithAppearance:self.effectiveAppearance];
}

@end

@implementation NSWindow (UIKitCompatTraits)

- (UITraitCollection *)traitCollection
{
  return [UITraitCollection traitCollectionWithAppearance:self.effectiveAppearance];
}

@end
