/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] Key input, which only a desktop platform has to model.
//
// Two shapes, and the distinction matters. `KeyEvent` is what a view reports
// happened. `HandledKey` is what a view declares in advance that it wants,
// which is a filter, not an event: AppKit gives a key to the responder chain
// and then to its own interpretation -- Tab moves focus, Escape cancels, an
// unclaimed key beeps -- so a view that means to act on a key has to say so
// before the press, or the default behaviour happens as well.
//
// Names follow https://www.w3.org/TR/uievents-key/ rather than AppKit's
// keyCodes, so `keyDownEvents={[{key: 'Enter'}]}` is the same declaration it
// would be on the web, and matches microsoft/react-native-macos.

#pragma once

#include <react/renderer/core/PropsParserContext.h>
#include <react/renderer/core/propsConversions.h>

#include <optional>
#include <string>
#include <unordered_map>

namespace facebook::react {

/**
 * A key the view intends to handle itself.
 *
 * A modifier left unset means "don't care": `{key: 'c'}` matches Cmd-C and a
 * bare c alike, while `{key: 'c', metaKey: true}` matches only the former.
 */
struct HandledKey {
  std::string key{};
  std::optional<bool> altKey{};
  std::optional<bool> ctrlKey{};
  std::optional<bool> shiftKey{};
  std::optional<bool> metaKey{};
};

inline bool operator==(const HandledKey &lhs, const HandledKey &rhs)
{
  return lhs.key == rhs.key && lhs.altKey == rhs.altKey && lhs.ctrlKey == rhs.ctrlKey &&
      lhs.shiftKey == rhs.shiftKey && lhs.metaKey == rhs.metaKey;
}

/** A key press, as reported to `onKeyDown` / `onKeyUp`. */
struct KeyEvent {
  std::string key{};
  bool altKey{false};
  bool ctrlKey{false};
  bool shiftKey{false};
  bool metaKey{false};
  bool capsLockKey{false};
  bool numericPadKey{false};
  bool helpKey{false};
  bool functionKey{false};
};

/** Whether an actual press satisfies a declaration; unset modifiers match anything. */
inline bool operator==(const KeyEvent &lhs, const HandledKey &rhs)
{
  return lhs.key == rhs.key && (!rhs.altKey.has_value() || lhs.altKey == *rhs.altKey) &&
      (!rhs.ctrlKey.has_value() || lhs.ctrlKey == *rhs.ctrlKey) &&
      (!rhs.shiftKey.has_value() || lhs.shiftKey == *rhs.shiftKey) &&
      (!rhs.metaKey.has_value() || lhs.metaKey == *rhs.metaKey);
}

/**
 * Accepts either the object form or a bare string, so `keyDownEvents={['Enter']}`
 * works as shorthand for the common no-modifier case.
 */
inline void fromRawValue(const PropsParserContext &context, const RawValue &value, HandledKey &result)
{
  if (value.hasType<std::unordered_map<std::string, RawValue>>()) {
    auto map = static_cast<std::unordered_map<std::string, RawValue>>(value);
    for (const auto &pair : map) {
      if (pair.first == "key") {
        result.key = static_cast<std::string>(pair.second);
      } else if (pair.first == "altKey") {
        result.altKey = static_cast<bool>(pair.second);
      } else if (pair.first == "ctrlKey") {
        result.ctrlKey = static_cast<bool>(pair.second);
      } else if (pair.first == "shiftKey") {
        result.shiftKey = static_cast<bool>(pair.second);
      } else if (pair.first == "metaKey") {
        result.metaKey = static_cast<bool>(pair.second);
      }
    }
  } else if (value.hasType<std::string>()) {
    result.key = static_cast<std::string>(value);
  }
}

} // namespace facebook::react
