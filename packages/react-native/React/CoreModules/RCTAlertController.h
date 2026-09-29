/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <UIKit/UIKit.h>

@interface RCTAlertController : RCTPlatformAlertController

- (void)show:(BOOL)animated completion:(void (^)(void))completion;
- (void)hide;

@end
