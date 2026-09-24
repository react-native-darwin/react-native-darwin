/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * UIKit re-exports NSUserActivity under its own umbrella. Foundation already
 * provides the class on macOS, so this header exists only to make the
 * <UIKit/UIUserActivity.h> import resolve.
 */

#pragma once

#import <Foundation/Foundation.h>
