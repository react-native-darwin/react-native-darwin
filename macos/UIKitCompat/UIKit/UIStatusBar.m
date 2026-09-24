/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIStatusBar.h"

@implementation UIStatusBarManager

- (CGRect)statusBarFrame
{
  return CGRectZero;
}

- (UIStatusBarStyle)statusBarStyle
{
  return UIStatusBarStyleDefault;
}

- (BOOL)isStatusBarHidden
{
  return YES;
}

@end
