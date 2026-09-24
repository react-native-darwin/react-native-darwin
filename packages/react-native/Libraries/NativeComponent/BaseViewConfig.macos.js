/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict-local
 * @format
 */

// [macOS] The view config decides which props reach native at all: anything
// missing from `validAttributes` is dropped before it ever gets to C++. So the
// macOS-only props declared in HostPlatformViewProps have to be listed here as
// well, or setting them does nothing.
//
// Everything iOS declares still applies, so this extends that config rather
// than replacing it. Names match microsoft/react-native-macos. macOS]

import type {PartialViewConfigWithoutName} from './PlatformBaseViewConfig';

// $FlowFixMe[cannot-resolve-module] macOS shares the iOS base config.
import PlatformBaseViewConfigIOS from './BaseViewConfig.ios';
import {ConditionallyIgnoredEventHandlers} from './ViewConfigIgnore';

const bubblingEventTypes = {
  ...PlatformBaseViewConfigIOS.bubblingEventTypes,
  topKeyDown: {
    phasedRegistrationNames: {
      captured: 'onKeyDownCapture',
      bubbled: 'onKeyDown',
    },
  },
  topKeyUp: {
    phasedRegistrationNames: {
      captured: 'onKeyUpCapture',
      bubbled: 'onKeyUp',
    },
  },
};

const directEventTypes = {
  ...PlatformBaseViewConfigIOS.directEventTypes,
  topDoubleClick: {registrationName: 'onDoubleClick'},
  topAuxClick: {registrationName: 'onAuxClick'},
  topMouseEnter: {registrationName: 'onMouseEnter'},
  topMouseLeave: {registrationName: 'onMouseLeave'},
  topDragEnter: {registrationName: 'onDragEnter'},
  topDragLeave: {registrationName: 'onDragLeave'},
  topDrop: {registrationName: 'onDrop'},
};

const validAttributesForNonEventProps = {
  acceptsFirstMouse: true,
  allowsVibrancy: true,
  draggedTypes: true,
  enableFocusRing: true,
  focusable: true,
  keyDownEvents: true,
  keyUpEvents: true,
  mouseDownCanMoveWindow: true,
  tooltip: true,
};

const validAttributesForEventProps = ConditionallyIgnoredEventHandlers({
  onAuxClick: true,
  onDoubleClick: true,
  onDragEnter: true,
  onDragLeave: true,
  onDrop: true,
  onKeyDown: true,
  onKeyUp: true,
  onMouseEnter: true,
  onMouseLeave: true,
});

const PlatformBaseViewConfigMacOS: PartialViewConfigWithoutName = {
  bubblingEventTypes,
  directEventTypes,
  validAttributes: {
    ...PlatformBaseViewConfigIOS.validAttributes,
    ...validAttributesForNonEventProps,
    // $FlowFixMe[exponential-spread]
    ...validAttributesForEventProps,
  },
};

export default PlatformBaseViewConfigMacOS;
