/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] See HostPlatformViewProps.h.

#include "HostPlatformViewProps.h"

#include <react/featureflags/ReactNativeFeatureFlags.h>
#include <react/renderer/core/propsConversions.h>

namespace facebook::react {

// The whole-map parsing path (feature flag off) needs a converter for the
// bitset, mirroring the one propsConversions.h provides for ViewEvents.
static inline HostPlatformViewEvents convertRawProp(
    const PropsParserContext &context,
    const RawProps &rawProps,
    const HostPlatformViewEvents &sourceValue,
    const HostPlatformViewEvents &defaultValue)
{
  HostPlatformViewEvents result{};
  using Offset = HostPlatformViewEvents::Offset;

#define RCT_MACOS_CONVERT_EVENT(name, offset)         \
  result[Offset::offset] = convertRawProp(            \
      context, rawProps, name, sourceValue[Offset::offset], defaultValue[Offset::offset])

  RCT_MACOS_CONVERT_EVENT("onMouseEnter", MouseEnter);
  RCT_MACOS_CONVERT_EVENT("onMouseLeave", MouseLeave);
  RCT_MACOS_CONVERT_EVENT("onDoubleClick", DoubleClick);
  RCT_MACOS_CONVERT_EVENT("onAuxClick", AuxClick);
  RCT_MACOS_CONVERT_EVENT("onKeyDown", KeyDown);
  RCT_MACOS_CONVERT_EVENT("onKeyUp", KeyUp);
  RCT_MACOS_CONVERT_EVENT("onDragEnter", DragEnter);
  RCT_MACOS_CONVERT_EVENT("onDragLeave", DragLeave);
  RCT_MACOS_CONVERT_EVENT("onDrop", Drop);

#undef RCT_MACOS_CONVERT_EVENT

  return result;
}

// Two parsing paths exist and both have to be fed. With the iterator setter
// feature flag on, props arrive one at a time through setProp and the
// constructor just carries the previous value forward; with it off, the
// constructor parses the whole RawProps map itself.
#define RCT_MACOS_PROP(name)                                    \
  name(ReactNativeFeatureFlags::enableCppPropsIteratorSetter()  \
           ? sourceProps.name                                   \
           : convertRawProp(context, rawProps, #name, sourceProps.name, {}))

HostPlatformViewProps::HostPlatformViewProps(
    const PropsParserContext &context,
    const HostPlatformViewProps &sourceProps,
    const RawProps &rawProps)
    : BaseViewProps(context, sourceProps, rawProps),
      hostPlatformEvents(
          ReactNativeFeatureFlags::enableCppPropsIteratorSetter()
              ? sourceProps.hostPlatformEvents
              : convertRawProp(context, rawProps, sourceProps.hostPlatformEvents, {})),
      RCT_MACOS_PROP(focusable),
      RCT_MACOS_PROP(enableFocusRing),
      RCT_MACOS_PROP(keyDownEvents),
      RCT_MACOS_PROP(keyUpEvents),
      RCT_MACOS_PROP(draggedTypes),
      RCT_MACOS_PROP(tooltip),
      RCT_MACOS_PROP(acceptsFirstMouse),
      RCT_MACOS_PROP(allowsVibrancy),
      RCT_MACOS_PROP(mouseDownCanMoveWindow)
{
}

#undef RCT_MACOS_PROP

void HostPlatformViewProps::setProp(
    const PropsParserContext &context,
    RawPropsPropNameHash hash,
    const char *propName,
    const RawValue &value)
{
  // Every Props struct must call super unconditionally: several structs can
  // share the same raw value, and skipping the call drops it for all of them.
  BaseViewProps::setProp(context, hash, propName, value);

  static auto defaults = HostPlatformViewProps{};

// An `onX` prop is stored as a bit rather than a value: all the view needs to
// know is whether anything is listening.
#define RCT_MACOS_EVENT_CASE(eventType)                                \
  case CONSTEXPR_RAW_PROPS_KEY_HASH("on" #eventType): {                \
    const auto offset = HostPlatformViewEvents::Offset::eventType;     \
    HostPlatformViewEvents defaultEvents{};                            \
    bool listening = defaultEvents[offset];                            \
    if (value.hasValue()) {                                            \
      fromRawValue(context, value, listening);                         \
    }                                                                  \
    hostPlatformEvents[offset] = listening;                            \
    return;                                                            \
  }

  switch (hash) {
    RCT_MACOS_EVENT_CASE(MouseEnter);
    RCT_MACOS_EVENT_CASE(MouseLeave);
    RCT_MACOS_EVENT_CASE(DoubleClick);
    RCT_MACOS_EVENT_CASE(AuxClick);
    RCT_MACOS_EVENT_CASE(KeyDown);
    RCT_MACOS_EVENT_CASE(KeyUp);
    RCT_MACOS_EVENT_CASE(DragEnter);
    RCT_MACOS_EVENT_CASE(DragLeave);
    RCT_MACOS_EVENT_CASE(Drop);
    RAW_SET_PROP_SWITCH_CASE_BASIC(focusable);
    RAW_SET_PROP_SWITCH_CASE_BASIC(enableFocusRing);
    RAW_SET_PROP_SWITCH_CASE_BASIC(keyDownEvents);
    RAW_SET_PROP_SWITCH_CASE_BASIC(keyUpEvents);
    RAW_SET_PROP_SWITCH_CASE_BASIC(draggedTypes);
    RAW_SET_PROP_SWITCH_CASE_BASIC(tooltip);
    RAW_SET_PROP_SWITCH_CASE_BASIC(acceptsFirstMouse);
    RAW_SET_PROP_SWITCH_CASE_BASIC(allowsVibrancy);
    RAW_SET_PROP_SWITCH_CASE_BASIC(mouseDownCanMoveWindow);
  }

#undef RCT_MACOS_EVENT_CASE
}

} // namespace facebook::react
