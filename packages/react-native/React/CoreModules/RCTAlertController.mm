/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTUtils.h>

#import <React/RCTAlertController.h>

@interface RCTAlertController ()

@property (nonatomic, strong) UIWindow *alertWindow;

@end

@implementation RCTAlertController

- (UIWindow *)alertWindow
{
  if (_alertWindow == nil) {
    UIWindowScene *scene = RCTKeyWindow().windowScene;
    if (scene != nil) {
      _alertWindow = [[UIWindow alloc] initWithWindowScene:scene];
      _alertWindow.frame = scene.coordinateSpace.bounds;
    } else {
      _alertWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    }

    if (_alertWindow != nullptr) {
      _alertWindow.rootViewController = [UIViewController new];
      _alertWindow.windowLevel = UIWindowLevelAlert + 1;
    }
  }

  return _alertWindow;
}

#if TARGET_OS_OSX // [macOS]
- (void)show:(__unused BOOL)animated completion:(void (^)(void))completion
{
  // The compatibility layer turns this controller into a real NSAlert, which
  // is run modally on a window rather than presented inside one. The iOS path
  // below builds a throwaway UIWindow to present into; doing that on AppKit
  // puts up an empty window and no alert. Hand the app's own window over
  // instead, so the alert comes down as a sheet on it.
  // RCTKeyWindow() is nil whenever another application holds focus, and a nil
  // window makes the alert run app-modal instead of coming down as a sheet.
  // Fall back to the app's own window so it always has one to attach to.
  NSWindow *window = RCTKeyWindow() ?: NSApp.mainWindow ?: NSApp.windows.firstObject;
  [self presentFromWindow:window];
  if (completion) {
    completion();
  }
}
#else // [macOS]

- (void)show:(BOOL)animated completion:(void (^)(void))completion
{
  UIUserInterfaceStyle style = self.overrideUserInterfaceStyle;
  if (style == UIUserInterfaceStyleUnspecified) {
    UIUserInterfaceStyle overriddenStyle = RCTKeyWindow().overrideUserInterfaceStyle;
    style = (overriddenStyle != 0) ? overriddenStyle : UIUserInterfaceStyleUnspecified;
  }

  self.overrideUserInterfaceStyle = style;

  [self.alertWindow makeKeyAndVisible];
  [self.alertWindow.rootViewController presentViewController:self animated:animated completion:completion];
}

#endif // [macOS]

- (void)hide
{
  [_alertWindow setHidden:YES];

  _alertWindow.windowScene = nil;

  _alertWindow = nil;
}

@end
