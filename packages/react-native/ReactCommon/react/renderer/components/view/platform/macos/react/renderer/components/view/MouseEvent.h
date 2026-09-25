/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] Pointer and drag payloads, which only a desktop platform reports.
//
// Free-standing rather than nested in the event emitter, because
// microsoft/react-native-macos puts `facebook::react::MouseEvent` and
// `DragEvent` here and third-party Fabric components name them directly.

#pragma once

#include <react/renderer/graphics/Float.h>

#include <optional>
#include <string>
#include <vector>

namespace facebook::react {

/** A mouse crossing, click or drag position. Fields follow the DOM MouseEvent. */
struct MouseEvent {
  /** Pointer location in the target view. */
  Float clientX{0};
  Float clientY{0};

  /** Pointer location in the window. */
  Float screenX{0};
  Float screenY{0};

  /**
   * Pointer location in the window as well. The DOM distinguishes page from
   * screen coordinates; AppKit has no document scroll offset to make them
   * differ, so both report the window position.
   */
  Float pageX{0};
  Float pageY{0};

  bool altKey{false};
  bool ctrlKey{false};
  bool shiftKey{false};
  bool metaKey{false};

  /** DOM button numbering: 0 primary, 1 auxiliary, 2 secondary. */
  int button{0};
};

/** One dragged file, described the way the DOM File interface does. */
struct DataTransferFile {
  std::string name{};
  std::string type{};

  /** A file path for a dragged file, or a data: URL for dragged image data. */
  std::string uri{};

  std::optional<int> size{};
  std::optional<int> width{};
  std::optional<int> height{};
};

struct DataTransferItem {
  /** "file" or "image". */
  std::string kind{};
  std::string type{};
};

/** The pasteboard contents of a drag, shaped like the DOM DataTransfer. */
struct DataTransfer {
  std::vector<DataTransferFile> files{};
  std::vector<DataTransferItem> items{};
  std::vector<std::string> types{};
};

struct DragEvent : MouseEvent {
  DataTransfer dataTransfer{};
};

} // namespace facebook::react
