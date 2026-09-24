/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] Keyboard focus is a real thing on macOS, so unlike the shared C++
// initializer this reports `focusable` views as keyboard-focusable.

#pragma once

#include <react/renderer/components/view/ViewProps.h>
#include <react/renderer/core/ShadowNodeTraits.h>

namespace facebook::react::HostPlatformViewTraitsInitializer {

inline bool formsStackingContext(const ViewProps & /*props*/)
{
  return false;
}

inline bool formsView(const ViewProps &props)
{
  // These all need a backing NSView, so a view carrying any of them must not be
  // flattened away: a focusable view has to join the key view loop, a tooltip
  // has to attach to something, and mouse tracking needs an NSTrackingArea
  // owner. Flattening is otherwise invisible -- the handler simply never fires.
  return props.focusable || props.tooltip.has_value() || props.hostPlatformEvents.bits.any() ||
      !props.keyDownEvents.empty() || !props.keyUpEvents.empty() || !props.draggedTypes.empty();
}

inline bool isKeyboardFocusable(const ViewProps &props)
{
  return props.focusable;
}

} // namespace facebook::react::HostPlatformViewTraitsInitializer
