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

/**
 * Deep linking integration supports two iOS lifecycle paths:
 * - **AppDelegate methods** (below): use when the app does not declare `UIApplicationSceneManifest` in Info.plist.
 * - **SceneDelegate methods** (below): use when the app uses the UIScene lifecycle. Forward these from your
 *   app-owned `SceneDelegate`.
 */

#pragma mark - AppDelegate methods

/// Lifecycle method informing of a URL being opened with the app.
/// Invoke from AppDelegate for non-scene apps (no `UIApplicationSceneManifest` in Info.plist).
/// Note: this is an implementation using the iOS 9.0-26.0 API
+ (BOOL)application:(nonnull RCTPlatformApplication *)app
            openURL:(nonnull NSURL *)URL
            options:(nonnull NSDictionary<RCTPlatformApplicationOpenURLOptionsKey, id> *)options;

/// Lifecycle method handling a URL being opened with the app.
/// Invoke from AppDelegate for non-scene apps.
/// Note: this is an implementation using the iOS 4.2-9.0 API
+ (BOOL)application:(nonnull RCTPlatformApplication *)application
              openURL:(nonnull NSURL *)URL
    sourceApplication:(nullable NSString *)sourceApplication
           annotation:(nonnull id)annotation;

/// Lifecycle method handling user activity being performed.
/// Invoke from AppDelegate for non-scene apps.
+ (BOOL)application:(nonnull RCTPlatformApplication *)application
    continueUserActivity:(nonnull NSUserActivity *)userActivity
      restorationHandler:(nonnull void (^)(NSArray<id<RCTPlatformUserActivityRestoring>> *_Nullable))restorationHandler;

#pragma mark - SceneDelegate methods

/// Handles user activity for scene-based apps. Invoke from your SceneDelegate.
+ (void)scene:(nonnull RCTPlatformScene *)scene // [macOS]
    continueUserActivity:(nonnull NSUserActivity *)userActivity;

/// Handles URLs opened while the app is running for scene-based apps. Invoke from your SceneDelegate.
+ (void)scene:(nonnull RCTPlatformScene *)scene // [macOS]
    openURLContexts:(nonnull NSSet<RCTPlatformOpenURLContext *> *)URLContexts;

@end
