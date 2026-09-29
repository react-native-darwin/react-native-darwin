/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <UIKit/UIKit.h>
#import "RCTReactNativeFactory.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Default delegate for RCTReactNativeFactory.
 * Contains default implementation of RCTReactNativeFactoryDelegate methods.
 */

@interface RCTDefaultReactNativeFactoryDelegate : RCTPlatformResponder <RCTReactNativeFactoryDelegate>
@end

NS_ASSUME_NONNULL_END
