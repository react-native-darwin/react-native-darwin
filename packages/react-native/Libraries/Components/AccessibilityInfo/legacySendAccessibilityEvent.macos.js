/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict-local
 * @format
 */

// [macOS] macOS resolves as `.macos` -> `.native` -> shared, so without this
// file `legacySendAccessibilityEvent` re-exports itself: the shared file is a
// stub that expects a platform-suffixed sibling to answer. Point it at the iOS
// implementation, which is what this fork uses on macOS wherever upstream has
// no platform-neutral one. macOS]

// NOTE: This file supports backwards compatibility of subpath (deep) imports
// from 'react-native' with platform-specific extensions. It can be deleted
// once we remove the "./*" mapping from package.json "exports".

import legacySendAccessibilityEvent from './legacySendAccessibilityEvent.ios';

export default legacySendAccessibilityEvent;
