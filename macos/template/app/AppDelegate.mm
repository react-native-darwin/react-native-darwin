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
#import <React/CoreModulesPlugins.h>
// The per-pod module providers. Each React Native pod vends its own Objective-C
// modules through one of these; there is no single registry to ask.
#import <React/RCTAnimationPlugins.h>
#import <RCTBlob/RCTBlobPlugins.h>
#import <React/RCTImagePlugins.h>
#import <React/RCTLinkingPlugins.h>
#import <React/RCTNetworkPlugins.h>
#import <React/RCTSettingsPlugins.h>
#import <React/RCTVibrationPlugins.h>
#import <React/RCTComponentViewFactory.h>
#import <ReactAppDependencyProvider/RCTAppDependencyProvider.h>
#import <React-RCTAppDelegate/RCTAppSetupUtils.h>
#import <ReactCommon/RCTHost.h>
#import <ReactCommon/RCTTurboModuleManager.h>
#import <react/featureflags/ReactNativeFeatureFlags.h>
#import <react/featureflags/ReactNativeFeatureFlagsOverridesOSSStable.h>
#import <react/nativemodule/defaults/DefaultTurboModules.h>

@interface AppDelegate () <RCTHostDelegate, RCTTurboModuleManagerDelegate, RCTComponentViewFactoryComponentProvider>
@property (nonatomic, readonly) RCTAppDependencyProvider *dependencyProvider;
@end

@implementation AppDelegate {
  RCTAppDependencyProvider *_dependencyProvider;
  RCTHost *_host;
  RCTFabricSurface *_surface;
  RCTSurfaceHostingView *_surfaceHostingView;
}

// A Mac app's keyboard shortcuts are its main menu: Cmd+V is not a keystroke
// the text system handles, it is a key equivalent that AppKit matches against
// the menu and turns into -paste:. An app with no menu cannot cut, copy,
// paste, undo or select all from the keyboard at all -- so this is the
// minimum, not decoration.
static NSMenu *RCTBuildMainMenu(void)
{
  NSString *appName = NSProcessInfo.processInfo.processName;
  NSMenu *mainMenu = [NSMenu new];

  NSMenuItem *appMenuItem = [NSMenuItem new];
  NSMenu *appMenu = [NSMenu new];
  [appMenu addItemWithTitle:[NSString stringWithFormat:@"About %@", appName]
                     action:@selector(orderFrontStandardAboutPanel:)
              keyEquivalent:@""];
  [appMenu addItem:[NSMenuItem separatorItem]];
  [appMenu addItemWithTitle:[NSString stringWithFormat:@"Hide %@", appName]
                     action:@selector(hide:)
              keyEquivalent:@"h"];
  NSMenuItem *hideOthers = [appMenu addItemWithTitle:@"Hide Others"
                                              action:@selector(hideOtherApplications:)
                                       keyEquivalent:@"h"];
  hideOthers.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
  [appMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
  [appMenu addItem:[NSMenuItem separatorItem]];
  [appMenu addItemWithTitle:[NSString stringWithFormat:@"Quit %@", appName]
                     action:@selector(terminate:)
              keyEquivalent:@"q"];
  appMenuItem.submenu = appMenu;
  [mainMenu addItem:appMenuItem];

  NSMenuItem *editMenuItem = [NSMenuItem new];
  NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
  [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
  NSMenuItem *redo = [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"z"];
  redo.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
  [editMenu addItem:[NSMenuItem separatorItem]];
  [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
  [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
  [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
  [editMenu addItemWithTitle:@"Delete" action:@selector(delete:) keyEquivalent:@""];
  [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
  editMenuItem.submenu = editMenu;
  [mainMenu addItem:editMenuItem];

  NSMenuItem *windowMenuItem = [NSMenuItem new];
  NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
  [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
  [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
  windowMenuItem.submenu = windowMenu;
  [mainMenu addItem:windowMenuItem];

  return mainMenu;
}

- (void)applicationDidFinishLaunching:(__unused NSNotification *)notification
{
  NSApp.mainMenu = RCTBuildMainMenu();

  // Autolinked Fabric components -- anything a third-party library registers
  // -- are reached through this, and a dependency provider alone is not
  // enough: that one covers turbo modules. Without it a library's views are
  // linked into the binary and still unknown to JavaScript, which fails with
  // "Cannot read property 'bubblingEventTypes' of undefined".
  [RCTComponentViewFactory currentComponentViewFactory].thirdPartyFabricComponentsProvider = self;

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

  _surface = [_host createSurfaceWithModuleName:@"__APP_NAME__" initialProperties:@{}];
  [_surface setMinimumSize:CGSizeMake(NSWidth(frame), NSHeight(frame))
               maximumSize:CGSizeMake(NSWidth(frame), NSHeight(frame))];

  _surfaceHostingView =
      [[RCTSurfaceHostingView alloc] initWithSurface:(id<RCTSurfaceProtocol>)_surface
                                     sizeMeasureMode:RCTSurfaceSizeMeasureModeWidthExact |
                                     RCTSurfaceSizeMeasureModeHeightExact];
  _surfaceHostingView.frame = frame;
  _surfaceHostingView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  // Host the surface inside an NSViewController rather than assigning it
  // straight to contentView. RCTUIKit's -reactViewController walks the
  // responder chain looking for a UIViewController; on macOS that is
  // NSViewController, and a window with no content view controller has none.
  // Modal presentation goes through it, so without this <Modal> silently
  // never opens.
  NSViewController *rootViewController = [NSViewController new];
  rootViewController.view = _surfaceHostingView;
  self.window.contentViewController = rootViewController;

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

- (Class)getModuleClassFromName:(const char *)name
{
  // Every pod vends its own modules through its own provider function, and
  // there is no registry that knows about all of them -- iOS reaches them
  // through a generated RCTTurboModulePluginClassProvider that is not built
  // here. So they are asked in turn.
  //
  // CoreModules alone is not enough, and the way it fails is memorable:
  // RCTNativeAnimatedModule lives in React-RCTAnimation, so every
  // `useNativeDriver: true` throws. That is not only Animated -- TouchableOpacity
  // animates opacity, <Button> wraps TouchableOpacity, and LogBox animates
  // too, which makes *any* warning blank the screen.
  using ClassProvider = Class (*)(const char *);
  static const ClassProvider providers[] = {
      RCTCoreModulesClassProvider,
      RCTAnimationClassProvider,
      RCTImageClassProvider,
      RCTNetworkClassProvider,
      RCTBlobClassProvider,
      RCTLinkingClassProvider,
      RCTSettingsClassProvider,
      RCTVibrationClassProvider,
  };

  for (ClassProvider provider : providers) {
    Class moduleClass = provider(name);
    if (moduleClass != nil) {
      return moduleClass;
    }
  }
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

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass
{
  // The dependency provider is codegen output: it carries the autolinked
  // modules and, importantly, the URL request handlers and image loaders that
  // RCTNetworking and RCTImageLoader ask it for. Constructing the module
  // without it is what leaves it half-wired.
  return RCTAppSetupDefaultModuleFromClass(moduleClass, self.dependencyProvider);
}

#pragma mark - RCTComponentViewFactoryComponentProvider

- (NSDictionary<NSString *, Class<RCTComponentViewProtocol>> *)thirdPartyFabricComponents
{
  return self.dependencyProvider.thirdPartyFabricComponents;
}

- (RCTAppDependencyProvider *)dependencyProvider
{
  if (_dependencyProvider == nil) {
    _dependencyProvider = [RCTAppDependencyProvider new];
  }
  return _dependencyProvider;
}

#pragma mark - Bundle

- (NSURL *)bundleURL
{
#if DEBUG
  // Pin the packager host explicitly rather than letting it default.
  //
  // `localhost` resolves to ::1 before 127.0.0.1, so any *other* dev server
  // already bound to *:8081 -- another project's Metro, which on a shared
  // machine is common -- is served instead, silently, with a bundle that is
  // valid and completely unrelated. The symptom is "main has not been
  // registered", and it sends you looking in the wrong place entirely.
  //
  // RCT_METRO_HOST_PORT overrides it for a one-off run; the stored jsLocation
  // (`defaults write <bundle-id> RCT_jsLocation 127.0.0.1:8099`) is the
  // persistent form, and is honoured when the variable is unset.
  NSString *hostPort = NSProcessInfo.processInfo.environment[@"RCT_METRO_HOST_PORT"];
  if (hostPort.length > 0) {
    RCTBundleURLProvider.sharedSettings.jsLocation = hostPort;
  } else if (RCTBundleURLProvider.sharedSettings.jsLocation.length == 0) {
    RCTBundleURLProvider.sharedSettings.jsLocation = @"127.0.0.1:8081";
  }
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
