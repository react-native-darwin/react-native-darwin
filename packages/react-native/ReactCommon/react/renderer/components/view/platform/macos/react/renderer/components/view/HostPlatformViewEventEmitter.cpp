/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] See HostPlatformViewEventEmitter.h.

#include "HostPlatformViewEventEmitter.h"

namespace facebook::react {

// Returns an Object, not a Value: dragEventPayload starts from one and adds to it.
static jsi::Object mouseEventPayload(jsi::Runtime &runtime, const MouseEvent &event)
{
  auto payload = jsi::Object(runtime);
  payload.setProperty(runtime, "clientX", event.clientX);
  payload.setProperty(runtime, "clientY", event.clientY);
  payload.setProperty(runtime, "screenX", event.screenX);
  payload.setProperty(runtime, "screenY", event.screenY);
  payload.setProperty(runtime, "pageX", event.pageX);
  payload.setProperty(runtime, "pageY", event.pageY);
  payload.setProperty(runtime, "altKey", event.altKey);
  payload.setProperty(runtime, "ctrlKey", event.ctrlKey);
  payload.setProperty(runtime, "shiftKey", event.shiftKey);
  payload.setProperty(runtime, "metaKey", event.metaKey);
  payload.setProperty(runtime, "button", event.button);
  // Pressability's click guard reads this to tell a real mouse click apart from
  // one synthesised by the responder system, which would otherwise fire onPress
  // twice.
  payload.setProperty(runtime, "pointerType", "mouse");
  return payload;
}

static jsi::Value keyEventPayload(jsi::Runtime &runtime, const KeyEvent &event)
{
  auto payload = jsi::Object(runtime);
  payload.setProperty(runtime, "key", jsi::String::createFromUtf8(runtime, event.key));
  payload.setProperty(runtime, "altKey", event.altKey);
  payload.setProperty(runtime, "ctrlKey", event.ctrlKey);
  payload.setProperty(runtime, "shiftKey", event.shiftKey);
  payload.setProperty(runtime, "metaKey", event.metaKey);
  payload.setProperty(runtime, "capsLockKey", event.capsLockKey);
  payload.setProperty(runtime, "numericPadKey", event.numericPadKey);
  payload.setProperty(runtime, "helpKey", event.helpKey);
  payload.setProperty(runtime, "functionKey", event.functionKey);
  return payload;
}

#define RCT_MACOS_MOUSE_EVENT(name)                                                   \
  void HostPlatformViewEventEmitter::name(const MouseEvent &event) const              \
  {                                                                                   \
    dispatchEvent(#name, [event](jsi::Runtime &runtime) {                             \
      return mouseEventPayload(runtime, event);                                       \
    });                                                                               \
  }

RCT_MACOS_MOUSE_EVENT(onMouseEnter)
RCT_MACOS_MOUSE_EVENT(onMouseLeave)
RCT_MACOS_MOUSE_EVENT(onDoubleClick)
RCT_MACOS_MOUSE_EVENT(onAuxClick)

#define RCT_MACOS_KEY_EVENT(name)                                                     \
  void HostPlatformViewEventEmitter::name(const KeyEvent &event) const                \
  {                                                                                   \
    dispatchEvent(#name, [event](jsi::Runtime &runtime) {                             \
      return keyEventPayload(runtime, event);                                         \
    });                                                                               \
  }

RCT_MACOS_KEY_EVENT(onKeyDown)
RCT_MACOS_KEY_EVENT(onKeyUp)

static jsi::Value dragEventPayload(jsi::Runtime &runtime, const DragEvent &event)
{
  auto dataTransfer = jsi::Object(runtime);

  auto files = jsi::Array(runtime, event.dataTransfer.files.size());
  for (size_t i = 0; i < event.dataTransfer.files.size(); i++) {
    const auto &file = event.dataTransfer.files[i];
    auto entry = jsi::Object(runtime);
    entry.setProperty(runtime, "name", jsi::String::createFromUtf8(runtime, file.name));
    entry.setProperty(runtime, "type", jsi::String::createFromUtf8(runtime, file.type));
    entry.setProperty(runtime, "uri", jsi::String::createFromUtf8(runtime, file.uri));
    // Absent rather than zero when unknown: a directory has no meaningful size,
    // and only an image has dimensions.
    if (file.size.has_value()) {
      entry.setProperty(runtime, "size", *file.size);
    }
    if (file.width.has_value()) {
      entry.setProperty(runtime, "width", *file.width);
    }
    if (file.height.has_value()) {
      entry.setProperty(runtime, "height", *file.height);
    }
    files.setValueAtIndex(runtime, i, entry);
  }
  dataTransfer.setProperty(runtime, "files", files);

  auto items = jsi::Array(runtime, event.dataTransfer.items.size());
  for (size_t i = 0; i < event.dataTransfer.items.size(); i++) {
    const auto &item = event.dataTransfer.items[i];
    auto entry = jsi::Object(runtime);
    entry.setProperty(runtime, "kind", jsi::String::createFromUtf8(runtime, item.kind));
    entry.setProperty(runtime, "type", jsi::String::createFromUtf8(runtime, item.type));
    items.setValueAtIndex(runtime, i, entry);
  }
  dataTransfer.setProperty(runtime, "items", items);

  auto types = jsi::Array(runtime, event.dataTransfer.types.size());
  for (size_t i = 0; i < event.dataTransfer.types.size(); i++) {
    types.setValueAtIndex(runtime, i, jsi::String::createFromUtf8(runtime, event.dataTransfer.types[i]));
  }
  dataTransfer.setProperty(runtime, "types", types);

  auto payload = mouseEventPayload(runtime, event);
  payload.setProperty(runtime, "dataTransfer", dataTransfer);
  return payload;
}

#define RCT_MACOS_DRAG_EVENT(name)                                                    \
  void HostPlatformViewEventEmitter::name(const DragEvent &event) const               \
  {                                                                                   \
    dispatchEvent(#name, [event](jsi::Runtime &runtime) {                             \
      return dragEventPayload(runtime, event);                                        \
    });                                                                               \
  }

RCT_MACOS_DRAG_EVENT(onDragEnter)
RCT_MACOS_DRAG_EVENT(onDragLeave)
RCT_MACOS_DRAG_EVENT(onDrop)

} // namespace facebook::react
