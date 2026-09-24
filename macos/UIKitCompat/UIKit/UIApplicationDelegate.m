/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIApplicationDelegate.h"

#import <sys/sysctl.h>

UIApplicationOpenURLOptionsKey const UIApplicationOpenURLOptionsSourceApplicationKey = @"UIApplicationOpenURLOptionsSourceApplicationKey";
UIApplicationOpenURLOptionsKey const UIApplicationOpenURLOptionsAnnotationKey = @"UIApplicationOpenURLOptionsAnnotationKey";
UIApplicationOpenURLOptionsKey const UIApplicationOpenURLOptionsOpenInPlaceKey = @"UIApplicationOpenURLOptionsOpenInPlaceKey";

UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsURLKey = @"UIApplicationLaunchOptionsURLKey";
UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsRemoteNotificationKey = @"UIApplicationLaunchOptionsRemoteNotificationKey";
UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsLocalNotificationKey = @"UIApplicationLaunchOptionsLocalNotificationKey";
UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsUserActivityDictionaryKey = @"UIApplicationLaunchOptionsUserActivityDictionaryKey";
UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsAnnotationKey = @"UIApplicationLaunchOptionsAnnotationKey";
UIApplicationLaunchOptionsKey const UIApplicationLaunchOptionsUserActivityTypeKey = @"UIApplicationLaunchOptionsUserActivityTypeKey";

// macOS has no per-app settings pane; System Settings is the nearest target.
NSString *const UIApplicationOpenSettingsURLString = @"x-apple.systempreferences:";
NSString *const UIContentSizeCategoryNewValueKey = @"UIContentSizeCategoryNewValueKey";

NSNotificationName const UIContentSizeCategoryDidChangeNotification = @"UIContentSizeCategoryDidChangeNotification";
NSNotificationName const UIKeyboardWillShowNotification = @"UIKeyboardWillShowNotification";
NSNotificationName const UIKeyboardDidShowNotification = @"UIKeyboardDidShowNotification";
NSNotificationName const UIKeyboardWillHideNotification = @"UIKeyboardWillHideNotification";
NSNotificationName const UIKeyboardDidHideNotification = @"UIKeyboardDidHideNotification";
NSNotificationName const UIKeyboardWillChangeFrameNotification = @"UIKeyboardWillChangeFrameNotification";
NSNotificationName const UIKeyboardDidChangeFrameNotification = @"UIKeyboardDidChangeFrameNotification";
NSNotificationName const UIAccessibilityLayoutChangedNotification = @"UIAccessibilityLayoutChangedNotification";
NSNotificationName const UIAccessibilityAnnouncementNotification = @"UIAccessibilityAnnouncementNotification";
NSNotificationName const UIAccessibilityScreenChangedNotification = @"UIAccessibilityScreenChangedNotification";

NSString *const UIKeyboardFrameEndUserInfoKey = @"UIKeyboardFrameEndUserInfoKey";
NSString *const UIKeyboardFrameBeginUserInfoKey = @"UIKeyboardFrameBeginUserInfoKey";
NSString *const UIKeyboardAnimationDurationUserInfoKey = @"UIKeyboardAnimationDurationUserInfoKey";
NSString *const UIKeyboardAnimationCurveUserInfoKey = @"UIKeyboardAnimationCurveUserInfoKey";
NSString *const UIKeyboardIsLocalUserInfoKey = @"UIKeyboardIsLocalUserInfoKey";

@implementation RCTUIKitCompatDevice

+ (UIDevice *)currentDevice
{
  static UIDevice *device;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    device = [UIDevice new];
  });
  return device;
}

- (NSString *)name
{
  return NSHost.currentHost.localizedName ?: @"Mac";
}

- (NSString *)systemName
{
  return @"macOS";
}

- (NSString *)systemVersion
{
  NSOperatingSystemVersion v = NSProcessInfo.processInfo.operatingSystemVersion;
  return [NSString stringWithFormat:@"%ld.%ld.%ld", (long)v.majorVersion, (long)v.minorVersion, (long)v.patchVersion];
}

- (NSString *)model
{
  // hw.model is the marketing-adjacent identifier, e.g. "Mac15,3".
  size_t length = 0;
  if (sysctlbyname("hw.model", NULL, &length, NULL, 0) != 0 || length == 0) {
    return @"Mac";
  }
  char *buffer = malloc(length);
  if (buffer == NULL) {
    return @"Mac";
  }
  NSString *model = @"Mac";
  if (sysctlbyname("hw.model", buffer, &length, NULL, 0) == 0) {
    model = [NSString stringWithUTF8String:buffer] ?: @"Mac";
  }
  free(buffer);
  return model;
}

- (UIUserInterfaceIdiom)userInterfaceIdiom
{
  return UIUserInterfaceIdiomMac;
}

- (BOOL)proximityState
{
  return NO;
}

- (UIDeviceOrientation)orientation
{
  return UIDeviceOrientationPortrait;
}

- (NSInteger)batteryState
{
  return 0;
}

- (float)batteryLevel
{
  return -1.0f;
}

@end
