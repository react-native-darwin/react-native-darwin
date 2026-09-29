/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <UIKit/UIKit.h>

@protocol RCTRedBoxExtraDataActionDelegate <NSObject>
- (void)reload;
@end

@interface RCTRedBoxExtraDataViewController : RCTPlatformViewController <RCTPlatformTableViewDelegate, RCTPlatformTableViewDataSource>

@property (nonatomic, weak) id<RCTRedBoxExtraDataActionDelegate> actionDelegate;

- (void)addExtraData:(NSDictionary *)data forIdentifier:(NSString *)identifier;

@end
