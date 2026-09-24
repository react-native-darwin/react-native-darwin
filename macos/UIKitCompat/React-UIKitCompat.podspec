# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

require "json"

# This podspec is used from two layouts and has to work in both:
#
#   in the repo      <repo>/macos/UIKitCompat          -> package.json is four
#                                                         levels up
#   in an npm tarball  node_modules/<pkg>/macos/UIKitCompat -> package.json is
#                                                         two levels up
#
# macos/scripts/publish.sh vendors this directory into the package when it
# publishes; nothing else about the layout changes.
package_json = [
  File.join(__dir__, "..", "..", "package.json"),
  File.join(__dir__, "..", "..", "packages", "react-native", "package.json"),
].find { |path| File.exist?(path) }
raise "React-UIKitCompat: cannot locate the react-native package.json" if package_json.nil?

package = JSON.parse(File.read(package_json))
version = package['version']

Pod::Spec.new do |s|
  s.name                   = "React-UIKitCompat"
  s.version                = version
  s.summary                = "UIKit compatibility layer for building React Native against AppKit."
  s.homepage               = "https://reactnative.dev/"
  s.license                = package["license"]
  s.author                 = "Meta Platforms, Inc. and its affiliates"
  s.source                 = { :git => "https://github.com/react-native-darwin/react-native-darwin.git", :tag => "v#{version}" }

  # macOS only. On every other platform the real UIKit is used, and shipping
  # these headers would shadow it.
  s.platforms              = { :osx => "14.0" }

  s.source_files           = "UIKit/**/*.{h,m}", "RCTPlatformTypes/**/*.h"
  s.header_dir             = "UIKit"

  # RCTPlatformTypes.h is the public half: the RCT* vocabulary, naming no UIKit
  # type, so it is safe on every pod's search path. Its own header_dir keeps it
  # reachable as <RCTPlatformTypes/RCTPlatformTypes.h> rather than under UIKit/.
  s.subspec 'RCTPlatformTypes' do |ss|
    ss.source_files = "RCTPlatformTypes/**/*.h"
    ss.header_dir   = "RCTPlatformTypes"
  end
  s.frameworks             = "AppKit", "QuartzCore"

  # Consumers reach the shim as <UIKit/UIKit.h>. That requires the *parent* of
  # the UIKit directory on the search path, not the directory itself.
  # DEFINES_MODULE is deliberately off. Turning it on makes CocoaPods emit a
  # clang module map declaring `module UIKit`, and a module by that name on
  # macOS poisons Swift's explicit-module graph: AuthenticationServices fails to
  # precompile because ASFoundation.h resolves the wrong branch of its
  # UIKit-versus-AppKit probe.
  #
  # Nothing needs the module. `#import <UIKit/UIKit.h>` is satisfied by the
  # header *directory* being on the search path, which is what the line below
  # does -- the parent of UIKit/, not UIKit/ itself.
  s.pod_target_xcconfig    = {
    "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)\""
  }
  # No user_target_xcconfig. The app reaches these headers through the
  # `post_install` hook in its Podfile, which is required anyway to force-include
  # RCTPlatformViewCompat.h. A path baked in here could only be correct for one
  # of the two layouts above.
end
