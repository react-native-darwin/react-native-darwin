/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <AppKit/AppKit.h>

#import "AppDelegate.h"

int main(int argc, const char *argv[])
{
  @autoreleasepool {
    NSApplication *application = NSApplication.sharedApplication;
    AppDelegate *delegate = [AppDelegate new];
    application.delegate = delegate;
    [application setActivationPolicy:NSApplicationActivationPolicyRegular];
    [application run];
  }
  return 0;
}
