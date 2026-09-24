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

- (NSInteger)forceTouchCapability
{
  return 1;  // UIForceTouchCapabilityUnavailable
}

- (BOOL)hasDifferentColorAppearanceComparedToTraitCollection:(UITraitCollection *)other
{
  if (other == nil) {
    return YES;
  }
  return _userInterfaceStyle != other.userInterfaceStyle ||
      _accessibilityContrast != other.accessibilityContrast;
}

+ (UITraitCollection *)traitCollectionWithUserInterfaceStyle:(UIUserInterfaceStyle)style
{
  UITraitCollection *traits = [UITraitCollection new];
  traits->_userInterfaceStyle = style;
  traits->_displayScale = NSScreen.mainScreen.backingScaleFactor ?: 1.0;
  return traits;
}

+ (UITraitCollection *)traitCollectionWithAccessibilityContrast:(UIAccessibilityContrast)contrast
{
  UITraitCollection *traits = [UITraitCollection new];
  traits->_accessibilityContrast = contrast;
  traits->_displayScale = NSScreen.mainScreen.backingScaleFactor ?: 1.0;
  return traits;
}

+ (UITraitCollection *)traitCollectionWithTraitsFromCollections:(NSArray<UITraitCollection *> *)collections
{
  // UIKit's rule: later collections win, and Unspecified does not override.
  UITraitCollection *merged = [UITraitCollection new];
  merged->_displayScale = NSScreen.mainScreen.backingScaleFactor ?: 1.0;
  for (UITraitCollection *collection in collections) {
    if (collection.userInterfaceStyle != UIUserInterfaceStyleUnspecified) {
      merged->_userInterfaceStyle = collection.userInterfaceStyle;
    }
    if (collection.accessibilityContrast != UIAccessibilityContrastUnspecified) {
      merged->_accessibilityContrast = collection.accessibilityContrast;
    }
    if (collection.displayScale > 0) {
      merged->_displayScale = collection.displayScale;
    }
  }
  return merged;
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
