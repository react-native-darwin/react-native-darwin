/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * The acceptance test for the migration off @compatibility_alias.
 *
 * This is a stand-in for expo-modules-core's Platform.h: a third-party pod
 * that declares the UIKit names itself -- as it must, and as reanimated,
 * safe-area-context and screens all do -- and then imports React Native.
 *
 * Before the migration this failed outright with "conflicting types for alias
 * 'UIView'", because the fork put a header declaring those same names on every
 * pod's search path. There is no way to yield at the preprocessor level, so
 * the only remedy was patching the other library. That is not a shipping
 * story, and this file is what stops it coming back.
 *
 * It is compiled with only the header search paths such a pod actually gets:
 * no shim, no -include prelude. See macos/PLAN-drop-uikit-aliases.md.
 */
#import <TargetConditionals.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>

// Exactly what expo-modules-core's Platform.h declares, and no more. That
// "no more" is the point: an earlier version of this test declared UIFont,
// UIViewController and UIBezierPath too, which no real library does -- they
// expect React Native to provide them -- and the test passed while
// expo-modules-core itself failed to build. A stand-in that is more
// self-sufficient than the real thing proves nothing.
@compatibility_alias UIView NSView;
@compatibility_alias UIResponder NSResponder;
@compatibility_alias UIColor NSColor;
@compatibility_alias UIWindow NSWindow;
@compatibility_alias UIImage NSImage;
@compatibility_alias UIImageView NSImageView;
#ifndef UIApplication
@compatibility_alias UIApplication NSApplication;
#endif
@protocol UIApplicationDelegate <NSApplicationDelegate> @end
@protocol UISceneDelegate <NSWindowDelegate> @end
#endif

#import <React/RCTUIKit.h>
#import <React/RCTView.h>
#import <React/RCTViewManager.h>
#import <React/RCTUtils.h>
#import <React/RCTConvert.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTRootView.h>
#import <React/RCTScrollView.h>
#import <React/UIView+React.h>

@interface ThirdPartyProbe : NSObject
@property (nonatomic, strong) UIView *ownView;         // its own alias
@property (nonatomic, strong) RCTPlatformView *rnView; // React Native's name
@property (nonatomic, strong) RCTUIView *concrete;     // react-native-macos's name
// Names the library does *not* declare, and expects React Native to provide.
// This is the half the earlier test was missing: expo-modules-core's
// EXReactDelegateWrapper.h fails on exactly this line without them.
- (UIViewController *)createRootViewController;
@property (nonatomic, strong) UIFont *font;
@end
@implementation ThirdPartyProbe
- (UIViewController *)createRootViewController { return nil; }
@end
