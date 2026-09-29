/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <React/RCTEventEmitter.h>
// [macOS] <UIKit/UIUserActivity.h> used to be imported here as well. An
// installed header must not name a shim header: third-party pods get a
// <UIKit/UIKit.h> that declares nothing, and nothing else.
#import <UIKit/UIKit.h>

@interface RCTLinkingManager : RCTEventEmitter

+ (BOOL)application:(nonnull RCTPlatformApplication *)app
            openURL:(nonnull NSURL *)URL
            options:(nonnull NSDictionary<RCTPlatformApplicationOpenURLOptionsKey, id> *)options;

+ (BOOL)application:(nonnull RCTPlatformApplication *)application
              openURL:(nonnull NSURL *)URL
    sourceApplication:(nullable NSString *)sourceApplication
           annotation:(nonnull id)annotation;

+ (BOOL)application:(nonnull RCTPlatformApplication *)application
    continueUserActivity:(nonnull NSUserActivity *)userActivity
      restorationHandler:(nonnull void (^)(NSArray<id<RCTPlatformUserActivityRestoring>> *_Nullable))restorationHandler;

@end
