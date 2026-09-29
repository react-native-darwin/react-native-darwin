/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <react/cxxstableapi/FrameworksGuard.h>

#include <react/renderer/attributedstring/ParagraphAttributes.h>
#include <react/renderer/attributedstring/TextAttributes.h>
#include <react/renderer/components/iostextinput/conversions.h>
#include <react/renderer/components/iostextinput/primitives.h>
#include <react/renderer/components/textinput/BaseTextInputProps.h>
#include <react/renderer/components/view/KeyEvent.h> // [macOS] for submitKeyEvents
#include <react/renderer/core/Props.h>
#include <react/renderer/core/PropsParserContext.h>
#include <react/renderer/core/propsConversions.h>
#include <react/renderer/imagemanager/primitives.h>
#include <optional> // [macOS] for the tri-state grammarCheck prop
#include <string>
#include <vector>

namespace facebook::react {

class TextInputProps final : public BaseTextInputProps {
 public:
  TextInputProps() = default;
  TextInputProps(const PropsParserContext &context, const TextInputProps &sourceProps, const RawProps &rawProps);

#pragma mark - Props
  const TextInputTraits traits{};

  /*
   * "Private" (only used by TextInput.js) props
   */
  std::optional<Selection> selection{};

  const std::string inputAccessoryViewID{};
  const std::string inputAccessoryViewButtonLabel{};

  bool onKeyPressSync{false};
  bool onChangeSync{false};

  // [macOS
  // macOS-only props, matching microsoft/react-native-macos.
  //
  // They live on this class rather than on TextInputTraits because traits are
  // shared with Android, which has no equivalent for any of them.

  // Clear the field after the user submits, rather than leaving the text in
  // place. AppKit has no equivalent; NSTextField keeps whatever was typed.
  bool clearTextOnSubmit{false};

  // Grammar checking, independent of spell checking. Unset means "leave
  // AppKit's default alone", which is why it is optional rather than a bool.
  std::optional<bool> grammarCheck{};

  // Multiline only: keep the text scrollable but draw no vertical scroller.
  bool hideVerticalScrollIndicator{false};

  // The pasteboard types onPaste should fire for. Empty means none, so a
  // component that does not ask for paste pays nothing.
  std::vector<std::string> pastedTypes{};

  // Key combinations that submit the field, in addition to Return. Reuses the
  // same descriptor as keyDownEvents so the two are described identically.
  std::vector<HandledKey> submitKeyEvents{};
  // macOS]
};

} // namespace facebook::react
