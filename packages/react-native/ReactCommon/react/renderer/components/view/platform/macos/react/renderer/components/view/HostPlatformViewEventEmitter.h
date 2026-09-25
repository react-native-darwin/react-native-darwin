/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] Adds the pointer and key events AppKit can report and UIKit cannot.

#pragma once

#include <react/renderer/components/view/BaseViewEventEmitter.h>

#include "KeyEvent.h"
#include "MouseEvent.h"

namespace facebook::react {

class HostPlatformViewEventEmitter : public BaseViewEventEmitter {
 public:
  using BaseViewEventEmitter::BaseViewEventEmitter;

  /**
   * Named here as well so `HostPlatformViewEventEmitter::MouseEvent` keeps
   * working; the type itself is free-standing, in MouseEvent.h.
   */
  using MouseEvent = ::facebook::react::MouseEvent;

  void onMouseEnter(const MouseEvent &event) const;
  void onMouseLeave(const MouseEvent &event) const;
  void onDoubleClick(const MouseEvent &event) const;
  void onAuxClick(const MouseEvent &event) const;

  void onKeyDown(const KeyEvent &event) const;
  void onKeyUp(const KeyEvent &event) const;

  /**
   * A drag passing over or finishing on the view. Only reported for views that
   * registered interest through the `draggedTypes` prop -- AppKit routes a drag
   * to the topmost view that registered for one of the pasteboard types it
   * carries, and ignores the rest.
   */
  void onDragEnter(const DragEvent &event) const;
  void onDragLeave(const DragEvent &event) const;
  void onDrop(const DragEvent &event) const;
};

} // namespace facebook::react
