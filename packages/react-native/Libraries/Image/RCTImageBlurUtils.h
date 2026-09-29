/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <Accelerate/Accelerate.h>
#import <UIKit/UIKit.h>

#import <React/RCTDefines.h>

RCT_EXTERN RCTPlatformImage *RCTBlurredImageWithRadius(RCTPlatformImage *inputImage, CGFloat radius);
