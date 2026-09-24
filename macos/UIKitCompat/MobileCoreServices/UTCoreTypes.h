/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * There is no MobileCoreServices.framework in the macOS SDK; the same
 * declarations live in CoreServices. Same trick as the UIKit directory: the
 * name is free on macOS, so upstream's import resolves here and needs no edit.
 */

#pragma once

#import <CoreServices/CoreServices.h>
