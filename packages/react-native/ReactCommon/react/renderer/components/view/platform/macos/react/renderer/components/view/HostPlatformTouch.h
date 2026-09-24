/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] Touch is the shared one; a mouse is reported through the same path.

#pragma once

#include <react/renderer/components/view/BaseTouch.h>

namespace facebook::react {
using HostPlatformTouch = BaseTouch;
} // namespace facebook::react
