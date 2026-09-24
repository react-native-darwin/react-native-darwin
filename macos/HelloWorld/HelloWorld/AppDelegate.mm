/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * The AppKit host layer, in the smallest form that actually renders.
 *
 * On iOS this work is done by RCTAppDelegate, which is built around
 * UIApplicationDelegate, UIWindow and a UIViewController. None of those have
 * the same shape on macOS, so the host is written directly against
 * NSApplication and NSWindow rather than ported.
 *
 * Everything below the surface -- RCTHost, RCTFabricSurface,
 * RCTSurfaceHostingView -- is unmodified upstream React Native.
 */

#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <React/RCTLog.h>
#import <React/RCTFabricSurface.h>
#import <React/RCTSurfaceHostingView.h>
#import <React/RCTSurfaceSizeMeasureMode.h>
#import <ReactCommon/RCTHermesInstance.h>
#import <ReactCommon/RCTHost.h>
#import <ReactCommon/RCTTurboModuleManager.h>
#import <react/featureflags/ReactNativeFeatureFlags.h>
#import <react/featureflags/ReactNativeFeatureFlagsOverridesOSSStable.h>
#import <react/nativemodule/defaults/DefaultTurboModules.h>

@interface AppDelegate () <RCTHostDelegate, RCTTurboModuleManagerDelegate>
@end

@implementation AppDelegate {
  RCTHost *_host;
  RCTFabricSurface *_surface;
  RCTSurfaceHostingView *_surfaceHostingView;
}

- (void)applicationDidFinishLaunching:(__unused NSNotification *)notification
{
  // Route every RCTLog -- including JS console output and redbox-worthy errors
  // -- to stderr. Without this a JS exception is invisible: there is no redbox
  // window on macOS yet, and the bare Metro server has no /logs middleware.
  RCTSetLogFunction(
      ^(RCTLogLevel level, __unused RCTLogSource source, NSString *fileName, NSNumber *lineNumber, NSString *message) {
        fprintf(stderr, "[RN:%d] %s (%s:%s)\n", (int)level, message.UTF8String,
                fileName.UTF8String ?: "?", lineNumber.stringValue.UTF8String ?: "?");
      });

  // RCTReactNativeFactory does this on iOS. Without it every feature flag keeps
  // its default, and `enableBridgelessArchitecture` defaults to false -- which
  // makes HermesInstance build its runtime with the microtask queue turned off.
  // React 19 schedules through microtasks, so the first render throws
  // "Could not enqueue microtask because they are disabled in this runtime"
  // and nothing is ever mounted. Must run before the runtime is created.
  facebook::react::ReactNativeFeatureFlags::override(
      std::make_unique<facebook::react::ReactNativeFeatureFlagsOverridesOSSStable>());

  NSRect frame = NSMakeRect(0, 0, 900, 640);
  self.window = [[NSWindow alloc] initWithContentRect:frame
                                            styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                                            NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
  self.window.title = @"React Native for macOS";
  [self.window center];

  _host = [[RCTHost alloc] initWithBundleURL:[self bundleURL]
                                hostDelegate:self
                  turboModuleManagerDelegate:self
                            jsEngineProvider:^std::shared_ptr<facebook::react::JSRuntimeFactory>() {
                              return std::make_shared<facebook::react::RCTHermesInstance>();
                            }
                               launchOptions:nil];
  [_host start];

  _surface = [_host createSurfaceWithModuleName:@"HelloWorld" initialProperties:@{}];
  [_surface setMinimumSize:CGSizeMake(NSWidth(frame), NSHeight(frame))
               maximumSize:CGSizeMake(NSWidth(frame), NSHeight(frame))];

  _surfaceHostingView =
      [[RCTSurfaceHostingView alloc] initWithSurface:(id<RCTSurfaceProtocol>)_surface
                                     sizeMeasureMode:RCTSurfaceSizeMeasureModeWidthExact |
                                     RCTSurfaceSizeMeasureModeHeightExact];
  _surfaceHostingView.frame = frame;
  _surfaceHostingView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  self.window.contentView = _surfaceHostingView;
  [self.window makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];
}

#pragma mark - RCTHostDelegate

- (void)hostDidStart:(__unused RCTHost *)host
{
  // Start the surface here, not at creation.
  //
  // AppRegistry installs its global binding while the bundle evaluates, and
  // RCTHost calls this delegate method once that has happened. Starting the
  // surface any earlier fails with "AppRegistryBinding::startSurface failed.
  // Global was not installed." -- which is silent unless you are listening for
  // JS errors, and leaves an empty window.
  [_surface start];
}

#pragma mark - RCTTurboModuleManagerDelegate

- (Class)getModuleClassFromName:(__unused const char *)name
{
  // nil on purpose, matching RCTDefaultReactNativeFactoryDelegate.
  // RCTTurboModuleManager resolves Objective-C modules through the codegen'd
  // RCTModuleProviders; answering here instead bypasses that and leaves the
  // module half-constructed, which surfaces in JS as a missing EventEmitter.
  return nil;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                      jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker
{
  // The built-in C++ TurboModules -- microtasks, feature flags, the DOM and
  // friends. Returning nullptr here leaves the runtime without them, and JS
  // dies on the first TurboModuleRegistry.getEnforcing('NativeMicrotasksCxx').
  return facebook::react::DefaultTurboModules::getTurboModule(name, jsInvoker);
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(__unused Class)moduleClass
{
  return nil;
}

#pragma mark - Bundle

- (NSURL *)bundleURL
{
#if DEBUG
  // Pin the packager host explicitly. `localhost` resolves to ::1 before
  // 127.0.0.1, so any other dev server already bound to *:8081 would be served
  // instead of ours -- silently, with a valid but completely unrelated bundle.
  // start-metro.js listens on the matching port.
  NSString *hostPort = NSProcessInfo.processInfo.environment[@"RCT_METRO_HOST_PORT"] ?: @"127.0.0.1:8082";
  RCTBundleURLProvider.sharedSettings.jsLocation = hostPort;
  return [RCTBundleURLProvider.sharedSettings jsBundleURLForBundleRoot:@"index"];
#else
  return [NSBundle.mainBundle URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(__unused NSApplication *)sender
{
  return YES;
}

@end
