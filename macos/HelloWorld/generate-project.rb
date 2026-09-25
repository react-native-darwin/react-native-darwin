# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Generates HelloWorld.xcodeproj.
#
# The project is generated rather than committed so that the fork carries no
# binary-ish pbxproj to merge. Run it once; `pod install` integrates with the
# result.

require 'fileutils'
require 'xcodeproj'

root = File.dirname(__FILE__)
path = File.join(root, 'HelloWorld.xcodeproj')
FileUtils.rm_rf(path)

project = Xcodeproj::Project.new(path)
target = project.new_target(:application, 'HelloWorld', :osx, '14.0')

group = project.new_group('HelloWorld', 'HelloWorld')
%w[main.m AppDelegate.mm].each do |file|
  target.add_file_references([group.new_reference(file)])
end
group.new_reference('AppDelegate.h')
group.new_reference('Info.plist')

target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'dev.reactnative.macos.helloworld'
  s['INFOPLIST_FILE'] = 'HelloWorld/Info.plist'
  s['CODE_SIGN_ENTITLEMENTS'] = 'HelloWorld/HelloWorld.entitlements'
  s['MACOSX_DEPLOYMENT_TARGET'] = '14.0'
  s['CLANG_ENABLE_OBJC_ARC'] = 'YES'
  s['CODE_SIGN_IDENTITY'] = '-'
  s['CODE_SIGNING_REQUIRED'] = 'NO'
  s['CODE_SIGNING_ALLOWED'] = 'NO'
  s['ALWAYS_SEARCH_USER_PATHS'] = 'NO'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/../Frameworks']
  s['ONLY_ACTIVE_ARCH'] = 'YES'
end

project.save
puts "generated #{path}"
