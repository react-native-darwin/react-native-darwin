/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] Which macOS-only handlers a view actually has.
//
// Installing an NSTrackingArea on every view to find out later would cost a
// mouse-moved dispatch per view per move. The props carry a bitset instead, so
// the view only tracks the mouse when something is listening -- the same
// arrangement BaseViewProps uses for pointer and responder events.

#pragma once

#include <bitset>
#include <cstddef>

namespace facebook::react {

struct HostPlatformViewEvents {
  std::bitset<16> bits{};

  enum class Offset : std::size_t {
    MouseEnter = 0,
    MouseLeave = 1,
    DoubleClick = 2,
    AuxClick = 3,
    KeyDown = 4,
    KeyUp = 5,
    DragEnter = 6,
    DragLeave = 7,
    Drop = 8,
  };

  constexpr bool operator[](Offset offset) const
  {
    return bits[static_cast<std::size_t>(offset)];
  }

  std::bitset<16>::reference operator[](Offset offset)
  {
    return bits[static_cast<std::size_t>(offset)];
  }

  /** True when any macOS mouse handler is present. */
  bool wantsMouseTracking() const
  {
    return (*this)[Offset::MouseEnter] || (*this)[Offset::MouseLeave];
  }
};

inline bool operator==(const HostPlatformViewEvents &lhs, const HostPlatformViewEvents &rhs)
{
  return lhs.bits == rhs.bits;
}

inline bool operator!=(const HostPlatformViewEvents &lhs, const HostPlatformViewEvents &rhs)
{
  return lhs.bits != rhs.bits;
}

} // namespace facebook::react
