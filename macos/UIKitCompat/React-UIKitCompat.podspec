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

  # The pod spans both platforms, but only one half of it does.
  #
  # RCTPlatformTypes.h is the public vocabulary -- RCTPlatformView, RCTUIColor
  # and the rest -- that installed headers are written in. Those headers are
  # compiled on iOS too, so the vocabulary has to resolve there; on iOS it is
  # simply the UIKit type under a neutral name.
  #
  # The UIKit shim is macOS only. On every other platform the real UIKit is
  # used, and shipping these headers would shadow it.
  # 15.1 matches Helpers::Constants.min_ios_version_supported. It is written
  # out rather than read from there because this podspec is evaluated from an
  # npm tarball layout too, where that file is not on the load path.
  s.platforms              = { :ios => "15.1", :osx => "14.0" }

  s.source_files           = "Public/RCTPlatformTypes/*.h"
  s.header_dir             = "RCTPlatformTypes"

  # The public <UIKit/UIKit.h>: it satisfies React Native's own import for
  # every consumer -- the app target included -- and declares nothing, so a
  # library is free to declare `UIView` itself. The real shim is the private
  # subspec below.
  s.subspec 'PublicUIKit' do |ss|
    ss.platforms    = { :osx => "14.0" }
    ss.source_files = "Public/UIKit/*.h"
    ss.header_dir   = "UIKit"
  end

  s.subspec 'UIKit' do |ss|
    ss.platforms    = { :osx => "14.0" }
    ss.source_files         = "UIKit/**/*.{h,m}"
    ss.header_dir           = "UIKit"
    # Private, not public. Installing these would put `UIView` and forty-odd
    # more names on every pod's search path, which is the thing this migration
    # exists to stop. This fork's own pods reach them through the header search
    # path that `apply_uikit_compat` adds, not through Pods/Headers/Public.
    ss.private_header_files = "UIKit/**/*.h"
    ss.frameworks   = "AppKit", "QuartzCore"
    ss.pod_target_xcconfig = {
      "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)\""
    }
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
