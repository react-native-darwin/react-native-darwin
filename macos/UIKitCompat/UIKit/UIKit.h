/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Umbrella header for the UIKit compatibility layer.
 *
 * This file exists so that an unmodified `#import <UIKit/UIKit.h>` in upstream
 * React Native source resolves here when building for the macosx SDK. The
 * directory is on HEADER_SEARCH_PATHS and is literally named UIKit, so no
 * upstream import needs to change.
 *
 * There is no UIKit.framework in the macOS SDK, so these names are free.
 * Verify with:
 *   ls $(xcrun --show-sdk-path --sdk macosx)/System/Library/Frameworks | grep -i uikit
 *
 * See MACOS-FORK.md.
 */

#pragma once

#include <TargetConditionals.h>

#if !TARGET_OS_OSX
#error "The UIKit compatibility layer is macOS-only. On iOS the real UIKit must be used."
#endif

#import <AppKit/AppKit.h>

#import "UIAccessibility.h"
#import "UIAlertController.h"
#import "UIApplication.h"
#import "UIApplicationDelegate.h"
#import "UIColor.h"
#import "UIDisplayLink.h"
#import "UIControls.h"
#import "UIEvent.h"
#import "UIGraphics.h"
#import "UIImage.h"
#import "UIKeyCommand.h"
#import "UIKitDefines.h"
#import "UIPlatformGaps.h"
#import "UIScrollView.h"
#import "UIStatusBar.h"
#import "UIText.h"
#import "UITraitCollection.h"
#import "UIUserActivity.h"
#import "UIViewAnimation.h"
#import "UIView.h"
