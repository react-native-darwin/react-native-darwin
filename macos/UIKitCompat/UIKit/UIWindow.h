/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Per-class forwarding header, matching real UIKit's layout.
 *
 * UIKit ships one header per class, and code probes for them by name to decide
 * which platform it is on. Apple's own SDK does it -- AuthenticationServices
 * takes its UIKit branch on `__has_include(<UIKit/UIKit.h>)`, then asks for
 * <UIKit/UIViewController.h> and <UIKit/UIWindow.h> to decide what
 * ASViewController and ASPresentationAnchor are. With the umbrella present but
 * those absent, it takes the UIKit branch and then defines neither, and the
 * framework fails to compile.
 *
 * So the rule is: this directory carries a per-class header for exactly the
 * classes the shim defines, and for no others. A probe for something we do not
 * have must keep failing, or the caller is told a lie.
 */

#pragma once

#import <UIKit/UIKit.h>
