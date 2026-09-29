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

@compatibility_alias UIView NSView;
@compatibility_alias UIResponder NSResponder;
@compatibility_alias UIColor NSColor;
@compatibility_alias UIImage NSImage;
@compatibility_alias UIViewController NSViewController;
@compatibility_alias UIApplication NSApplication;
@compatibility_alias UIWindow NSWindow;
@compatibility_alias UIFont NSFont;
@compatibility_alias UIScreen NSScreen;
@compatibility_alias UIBezierPath NSBezierPath;
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
@end
@implementation ThirdPartyProbe
@end
