/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <React/RCTBridge.h>
#import <React/RCTSurfacePresenterStub.h>
#import <React/RCTSurfaceView.h>
#import <UIKit/UIKit.h>

@interface RCTLogBoxView : RCTPlatformWindow

- (instancetype)initWithFrame:(CGRect)frame;

- (void)createRootViewController:(RCTPlatformView *)view;

- (instancetype)initWithWindow:(RCTPlatformWindow *)window surfacePresenter:(id<RCTSurfacePresenterStub>)surfacePresenter;

- (void)show;

@end
