/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

// [macOS] An installed header must not name a UIKit type: the aliases would
// leak into every dependent's translation unit and collide with whatever else
// declares them. RCTPlatformTypes.h is the half of the compatibility layer
// that names none. See macos/PLAN-drop-uikit-aliases.md.
#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <vector>

namespace facebook::react {
struct ColorComponents;
struct Color;
} // namespace facebook::react

facebook::react::ColorComponents RCTPlatformColorComponentsFromSemanticItems(std::vector<std::string> &semanticItems);
// [macOS] RCTUIColor, not UIColor: an installed header must not name a UIKit
// type. Same type either way -- NSColor here, UIColor on iOS.
RCTUIColor *RCTPlatformColorFromSemanticItems(std::vector<std::string> &semanticItems);
RCTUIColor *RCTPlatformColorFromColor(const facebook::react::Color &color);
