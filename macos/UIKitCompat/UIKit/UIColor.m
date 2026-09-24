/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIColor.h"

@implementation NSColor (UIKitCompat)

+ (NSColor *)colorWithDynamicProvider:(NSColor * (^)(id))provider
{
  return [NSColor colorWithName:nil
                dynamicProvider:^NSColor *(NSAppearance *appearance) {
                  return provider(appearance);
                }];
}

+ (NSColor *)systemBackgroundColor
{
  return NSColor.windowBackgroundColor;
}

+ (NSColor *)secondarySystemBackgroundColor
{
  return NSColor.underPageBackgroundColor;
}

+ (NSColor *)labelColor2
{
  return NSColor.secondaryLabelColor;
}

+ (NSColor *)systemGray6Color
{
  return NSColor.underPageBackgroundColor;
}

- (CGColorRef)UIKitCompatCGColor
{
  NSColor *rgb = [self colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
  return rgb.CGColor ?: self.CGColor;
}

- (NSColor *)resolvedColorWithAppearance:(NSAppearance *)appearance
{
  if (appearance == nil) {
    return self;
  }
  __block NSColor *resolved = self;
  [appearance performAsCurrentDrawingAppearance:^{
    // Forcing a space conversion is what actually collapses a dynamic colour
    // down to a concrete one under the active appearance.
    resolved = [self colorUsingColorSpace:[NSColorSpace sRGBColorSpace]] ?: self;
  }];
  return resolved;
}

- (BOOL)UIKitCompatGetRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha
{
  NSColor *rgb = [self colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
  if (rgb == nil) {
    return NO;
  }
  if (red) {
    *red = rgb.redComponent;
  }
  if (green) {
    *green = rgb.greenComponent;
  }
  if (blue) {
    *blue = rgb.blueComponent;
  }
  if (alpha) {
    *alpha = rgb.alphaComponent;
  }
  return YES;
}

@end


