/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTSwiftUIContainerViewWrapper.h"

#if !TARGET_OS_OSX // [macOS]
@import RCTSwiftUI;
#endif // [macOS]

#if !TARGET_OS_OSX // [macOS]

@interface RCTSwiftUIContainerViewWrapper ()
@property (nonatomic, strong) RCTSwiftUIContainerView *swiftContainerView;
@end

@implementation RCTSwiftUIContainerViewWrapper

- (instancetype)init
{
  if (self = [super init]) {
    _swiftContainerView = [RCTSwiftUIContainerView new];
  }
  return self;
}

- (UIView *_Nullable)contentView
{
  return [self.swiftContainerView contentView];
}

- (UIView *_Nullable)hostingView
{
  return [self.swiftContainerView hostingView];
}

- (void)resetStyles
{
  [self.swiftContainerView resetStyles];
}

- (void)updateContentView:(UIView *)view
{
  return [self.swiftContainerView updateContentView:view];
}

- (void)updateBlurRadius:(NSNumber *)radius
{
  [self.swiftContainerView updateBlurRadius:radius];
}

- (void)updateGrayscale:(NSNumber *)grayscale
{
  [self.swiftContainerView updateGrayscale:grayscale];
}

- (void)updateSaturation:(NSNumber *)saturation
{
  [self.swiftContainerView updateSaturation:saturation];
}

- (void)updateContrast:(NSNumber *)contrast
{
  [self.swiftContainerView updateContrast:contrast];
}

- (void)updateHueRotate:(NSNumber *)degrees
{
  [self.swiftContainerView updateHueRotate:degrees];
}

- (void)updateDropShadow:(NSNumber *)standardDeviation x:(NSNumber *)x y:(NSNumber *)y color:(UIColor *)color
{
  [self.swiftContainerView updateDropShadowWithStandardDeviation:standardDeviation x:x y:y color:color];
}

- (void)updateLayoutWithBounds:(CGRect)bounds
{
  [self.swiftContainerView updateLayoutWithBounds:bounds];
}

@end

#else // [macOS

/**
 * The SwiftUI container backs CSS filter effects -- blur, grayscale, saturate,
 * drop-shadow -- by hosting the view inside a SwiftUI hierarchy. The Swift half
 * of it imports UIKit and so is not built for macOS.
 *
 * These are no-ops rather than an error: a view with a filter style renders
 * without the filter instead of failing to render at all. Porting the container
 * to SwiftUI-on-AppKit is separate work.
 */
@implementation RCTSwiftUIContainerViewWrapper

- (UIView *_Nullable)contentView
{
  return nil;
}

- (UIView *_Nullable)hostingView
{
  return nil;
}

- (void)resetStyles
{
}

- (void)updateContentView:(__unused UIView *)view
{
}

- (void)updateBlurRadius:(__unused NSNumber *)radius
{
}

- (void)updateGrayscale:(__unused NSNumber *)grayscale
{
}

- (void)updateSaturation:(__unused NSNumber *)saturation
{
}

- (void)updateContrast:(__unused NSNumber *)contrast
{
}

- (void)updateHueRotate:(__unused NSNumber *)degrees
{
}

- (void)updateDropShadow:(__unused NSNumber *)standardDeviation
                       x:(__unused NSNumber *)x
                       y:(__unused NSNumber *)y
                   color:(__unused UIColor *)color
{
}

- (void)updateLayoutWithBounds:(__unused CGRect)bounds
{
}

@end

#endif // macOS]
