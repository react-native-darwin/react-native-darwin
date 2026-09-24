/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] The props a Mac view has and an iOS one does not.
//
// React Native reaches platform-specific view props through this class -- see
// the sibling directories under components/view/platform. Adding them here
// means no shared C++ changes at all, and the names match
// microsoft/react-native-macos so code written against that fork type-checks
// and behaves the same.

#pragma once

#include <react/renderer/components/view/BaseViewProps.h>
#include <react/renderer/core/PropsParserContext.h>

#include <optional>
#include <string>
#include <vector>

#include "HostPlatformViewEvents.h"
#include "KeyEvent.h"

namespace facebook::react {

class HostPlatformViewProps : public BaseViewProps {
 public:
  HostPlatformViewProps() = default;
  HostPlatformViewProps(
      const PropsParserContext &context,
      const HostPlatformViewProps &sourceProps,
      const RawProps &rawProps);

  void
  setProp(const PropsParserContext &context, RawPropsPropNameHash hash, const char *propName, const RawValue &value);

  /** Which macOS-only handlers are attached; see HostPlatformViewEvents. */
  HostPlatformViewEvents hostPlatformEvents{};

#pragma mark - Props

  /** Participates in the key view loop, i.e. reachable by Tab. */
  bool focusable{false};

  /** Draws the focus ring while first responder. On by default, as in AppKit. */
  bool enableFocusRing{true};

  /**
   * Keys the view handles itself, rather than letting AppKit interpret them.
   * See HandledKey: a press not declared here still reaches onKeyDown, but
   * AppKit's own handling runs afterwards.
   */
  std::vector<HandledKey> keyDownEvents{};
  std::vector<HandledKey> keyUpEvents{};

  /**
   * Which kinds of dragged content the view accepts: "fileUrl", "image",
   * "string". Empty means the view takes no part in drag and drop -- AppKit
   * routes a drag only to views that registered for one of its pasteboard
   * types, so this is what makes onDragEnter/onDrop reachable at all.
   */
  std::vector<std::string> draggedTypes{};

  /** The view's help tag. std::nullopt leaves any inherited tooltip alone. */
  std::optional<std::string> tooltip{};

  /** Take the click that activates a background window, rather than swallowing it. */
  bool acceptsFirstMouse{false};

  /** Let the view sit in an NSVisualEffectView and blend with what is behind it. */
  bool allowsVibrancy{false};

  /**
   * Whether dragging the view moves the window. AppKit's default is true, and
   * that is kept here: a view that opts out is the interesting case.
   */
  bool mouseDownCanMoveWindow{true};
};

} // namespace facebook::react
