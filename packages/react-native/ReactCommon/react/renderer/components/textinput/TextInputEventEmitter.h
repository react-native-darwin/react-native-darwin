/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <react/renderer/attributedstring/AttributedString.h>
#include <string> // [macOS] for the paste and setting-change payloads
#include <vector> // [macOS]
#include <react/renderer/components/view/ViewEventEmitter.h>

namespace facebook::react {

class TextInputEventEmitter : public ViewEventEmitter {
 public:
  using ViewEventEmitter::ViewEventEmitter;

  struct Metrics {
    std::string text;
    AttributedString::Range selectionRange;
    // ScrollView-like metrics
    Size contentSize;
    Point contentOffset;
    EdgeInsets contentInset;
    Size containerSize;
    int eventCount;
    Size layoutMeasurement;
    Float zoomScale;
    Tag target;
  };

  struct KeyPressMetrics {
    std::string text;
    int eventCount;
  };

  void onFocus(const Metrics &textInputMetrics) const;
  void onBlur(const Metrics &textInputMetrics) const;
  void onChange(const Metrics &textInputMetrics) const;
  void onContentSizeChange(const Metrics &textInputMetrics) const;
  void onSelectionChange(const Metrics &textInputMetrics) const;
  void onEndEditing(const Metrics &textInputMetrics) const;
  void onSubmitEditing(const Metrics &textInputMetrics) const;
  void onKeyPress(const KeyPressMetrics &keyPressMetrics) const;
  void onScroll(const Metrics &textInputMetrics) const;

  // [macOS
  // macOS-only events, matching microsoft/react-native-macos. The context
  // menu on a Mac lets the user turn autocorrect, spell checking and grammar
  // checking on and off per field, and an app that mirrors those settings in
  // its own UI needs to hear about it.
  struct SettingChangeMetrics {
    bool enabled;
  };

  // One item off the pasteboard. A file has a uri and dimensions; a string
  // has neither.
  struct PastedItem {
    std::string kind;
    std::string type;
    std::string uri;
    Float width;
    Float height;
    int size;
  };

  struct PasteMetrics {
    std::vector<PastedItem> items;
  };

  void onPaste(const PasteMetrics &pasteMetrics) const;
  void onAutoCorrectChange(const SettingChangeMetrics &metrics) const;
  void onSpellCheckChange(const SettingChangeMetrics &metrics) const;
  void onGrammarCheckChange(const SettingChangeMetrics &metrics) const;
  // macOS]

 private:
  void dispatchTextInputEvent(
      const std::string &name,
      const Metrics &textInputMetrics,
      bool includeSelectionState = false) const;

  void dispatchTextInputContentSizeChangeEvent(const std::string &name, const Metrics &textInputMetrics) const;
};

} // namespace facebook::react
