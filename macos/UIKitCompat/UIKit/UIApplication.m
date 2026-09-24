/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIApplication.h"

NSNotificationName const UIApplicationDidReceiveMemoryWarningNotification =
    @"UIApplicationDidReceiveMemoryWarningNotification";

@implementation NSApplication (UIKitCompat)

- (UIApplicationState)applicationState
{
  return self.isActive ? UIApplicationStateActive : UIApplicationStateInactive;
}

- (NSWindow *)keyWindowForUIKitCompat
{
  return self.keyWindow ?: self.mainWindow ?: self.windows.firstObject;
}

- (BOOL)openURL:(NSURL *)url
{
  return [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
