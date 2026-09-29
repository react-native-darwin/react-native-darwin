/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RCTUtilsUIOverride : NSObject
/**
 Set the global presented view controller instance override.
 */
+ (void)setPresentedViewController:(RCTPlatformViewController *)presentedViewController;
+ (RCTPlatformViewController *)presentedViewController;
+ (BOOL)hasPresentedViewController;

@end
