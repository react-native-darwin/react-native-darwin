/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * UIKit exposes the mutable `state` to gesture recogniser subclasses through
 * this separate header. NSGestureRecognizer already declares `state` as
 * readwrite, so nothing is needed beyond making the import resolve.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIKitDefines.h"
