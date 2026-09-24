/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIApplication.h"
#import "UIKitDefines.h"

// The shim's compile-time names, which is all this layer is for.
//
// Deliberately aliases rather than real classes: registering a UIKit name
// with the ObjC runtime makes Apple's own frameworks mistake the process for
// Catalyst. macOS's one-time-code AutoFill does exactly that for the focused
// text field, and answering yes sends it into UIKitMacHelper, which dlopens a
// UIKit.framework that does not exist here and takes the process down.
//
// Forward-declared first so the aliases can appear before anything uses them.
@class RCTUIKitCompatDevice;
@compatibility_alias UIDevice RCTUIKitCompatDevice;


NS_ASSUME_NONNULL_BEGIN

typedef NSString *UIApplicationOpenURLOptionsKey NS_TYPED_ENUM;
extern UIApplicationOpenURLOptionsKey const UIApplicationOpenURLOptionsSourceApplicationKey;
extern UIApplicationOpenURLOptionsKey const UIApplicationOpenURLOptionsAnnotationKey;
extern UIApplicationOpenURLOptionsKey const UIApplicationOpenURLOptionsOpenInPlaceKey;

typedef NSString *UIApplicationLaunchOptionsKey NS_TYPED_ENUM;
extern UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsURLKey;
extern UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsRemoteNotificationKey;
extern UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsLocalNotificationKey;
extern UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsUserActivityDictionaryKey;
extern UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsAnnotationKey;
extern UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsUserActivityTypeKey;

/**
 * UIApplicationDelegate, expressed over NSApplicationDelegate.
 *
 * The two lifecycles are not the same shape -- macOS has no scene model, no
 * background execution, and different launch callbacks -- so this declares the
 * subset React Native's RCTAppDelegate actually implements, and inherits
 * NSApplicationDelegate so the object can still be handed to NSApplication.
 */
@protocol UIApplicationDelegate <NSApplicationDelegate>
@optional
@property (nonatomic, strong, nullable) NSWindow *window;
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;
- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)applicationWillResignActive:(UIApplication *)application;
- (void)applicationWillTerminate:(UIApplication *)application;
@end

typedef NS_ENUM(NSInteger, UIDeviceOrientation) {
  UIDeviceOrientationUnknown = 0,
  UIDeviceOrientationPortrait,
  UIDeviceOrientationPortraitUpsideDown,
  UIDeviceOrientationLandscapeLeft,
  UIDeviceOrientationLandscapeRight,
  UIDeviceOrientationFaceUp,
  UIDeviceOrientationFaceDown,
};

typedef NS_ENUM(NSInteger, UIInterfaceOrientation) {
  UIInterfaceOrientationUnknown = 0,
  UIInterfaceOrientationPortrait,
  UIInterfaceOrientationPortraitUpsideDown,
  UIInterfaceOrientationLandscapeLeft,
  UIInterfaceOrientationLandscapeRight,
};

typedef NS_ENUM(NSInteger, UIUserInterfaceIdiom) {
  UIUserInterfaceIdiomUnspecified = -1,
  UIUserInterfaceIdiomPhone = 0,
  UIUserInterfaceIdiomPad = 1,
  UIUserInterfaceIdiomTV = 2,
  UIUserInterfaceIdiomCarPlay = 3,
  UIUserInterfaceIdiomMac = 5,
  UIUserInterfaceIdiomVision = 6,
};

/**
 * UIDevice, answered from the host.
 *
 * Only what React Native reads: a name, a system version, and an idiom. The
 * idiom is always Mac, which is the truthful answer.
 */
@interface RCTUIKitCompatDevice : NSObject
@property (class, nonatomic, readonly) UIDevice *currentDevice;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *systemName;
@property (nonatomic, readonly, copy) NSString *systemVersion;
@property (nonatomic, readonly, copy) NSString *model;
@property (nonatomic, readonly) UIUserInterfaceIdiom userInterfaceIdiom;
// No proximity sensor on a Mac.
@property (nonatomic, assign, getter=isProximityMonitoringEnabled) BOOL proximityMonitoringEnabled;
@property (nonatomic, readonly) BOOL proximityState;
@property (nonatomic, readonly) NSInteger batteryState;
@property (nonatomic, readonly) float batteryLevel;
// A Mac display does not rotate.
@property (nonatomic, readonly) UIDeviceOrientation orientation;
@end

NS_INLINE BOOL UIDeviceOrientationIsLandscape(UIDeviceOrientation orientation)
{
  return orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight;
}

NS_INLINE BOOL UIDeviceOrientationIsPortrait(UIDeviceOrientation orientation)
{
  return orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown;
}

typedef NS_ENUM(NSInteger, UIForceTouchCapability) {
  UIForceTouchCapabilityUnknown = 0,
  UIForceTouchCapabilityUnavailable = 1,
  UIForceTouchCapabilityAvailable = 2,
};

// Dynamic Type and keyboard notifications have no macOS counterpart. Declared
// so upstream observers register successfully; they never fire.
extern NSString *const UIApplicationOpenSettingsURLString;
extern NSString *const UIContentSizeCategoryNewValueKey;


extern NSNotificationName const UIContentSizeCategoryDidChangeNotification;
extern NSNotificationName const UIKeyboardWillShowNotification;
extern NSNotificationName const UIKeyboardDidShowNotification;
extern NSNotificationName const UIKeyboardWillHideNotification;
extern NSNotificationName const UIKeyboardDidHideNotification;
extern NSNotificationName const UIKeyboardWillChangeFrameNotification;
extern NSNotificationName const UIKeyboardDidChangeFrameNotification;
extern NSNotificationName const UIAccessibilityLayoutChangedNotification;
extern NSNotificationName const UIAccessibilityAnnouncementNotification;
extern NSNotificationName const UIAccessibilityScreenChangedNotification;

extern NSString *const UIKeyboardFrameEndUserInfoKey;
extern NSString *const UIKeyboardFrameBeginUserInfoKey;
extern NSString *const UIKeyboardAnimationDurationUserInfoKey;
extern NSString *const UIKeyboardAnimationCurveUserInfoKey;
extern NSString *const UIKeyboardIsLocalUserInfoKey;

/**
 * A window delegate, which is the closest AppKit has to a scene delegate. macOS
 * has no scene lifecycle, so this is the protocol's shape and nothing more.
 * expo-modules-core declares it in its own macOS header; having it here means
 * that header can defer to this one wholesale.
 */
@protocol UISceneDelegate <NSWindowDelegate>
@end

// No UIHostingController. NSHostingController is a Swift-only type -- SwiftUI
// does not vend it to Objective-C -- so there is nothing to alias it to. Code
// that needs a hosting controller has to reach it from Swift.

NS_ASSUME_NONNULL_END
