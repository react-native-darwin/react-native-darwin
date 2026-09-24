# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

require "json"

package = JSON.parse(File.read(File.join(__dir__, "..", "..", "packages", "react-native", "package.json")))
version = package['version']

Pod::Spec.new do |s|
  s.name                   = "React-UIKitCompat"
  s.version                = version
  s.summary                = "UIKit compatibility layer for building React Native against AppKit."
  s.homepage               = "https://reactnative.dev/"
  s.license                = package["license"]
  s.author                 = "Meta Platforms, Inc. and its affiliates"
  s.source                 = { :git => "https://github.com/gabrieldonadel/react-native-macos.git", :tag => "v#{version}" }

  # macOS only. On every other platform the real UIKit is used, and shipping
  # these headers would shadow it.
  s.platforms              = { :osx => "11.0" }

  s.source_files           = "UIKit/**/*.{h,m}"
  s.header_dir             = "UIKit"
  s.frameworks             = "AppKit", "QuartzCore"

  # Consumers reach the shim as <UIKit/UIKit.h>. That requires the *parent* of
  # the UIKit directory on the search path, not the directory itself.
  s.pod_target_xcconfig    = {
    "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)\"",
    "DEFINES_MODULE" => "YES"
  }
  s.user_target_xcconfig   = {
    "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/../../macos/UIKitCompat\""
  }
end
