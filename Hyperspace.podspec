#
# Be sure to run `pod lib lint Hyperspace.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Hyperspace'
  s.version          = '4.1.0'
  s.summary          = 'An extremely lightweight wrapper around URLSession to make working with APIs a breeze.'

  s.description      = <<-DESC
Hyperspace attempts to take the boilerplate out of working with HTTP in your app.
Unlike other networking libraries, the goal of Hyperspace is to keep things simple and maintain a minimal (but useful) feature set.
                       DESC

  s.homepage         = 'https://github.com/BottleRocketStudios/iOS-Hyperspace'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.author           = { 'Tyler Milner' => 'tyler.milner@bottlerocketstudios.com' }
  s.source           = { :git => 'https://github.com/BottleRocketStudios/iOS-Hyperspace.git', :tag => s.version.to_s }

  s.swift_version = '5.6'
  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '6.0'
  s.macos.deployment_target = '11.0'
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
  core.source_files = 'Sources/Core/**/*', 'Sources/Async/**/*'
  end

  s.subspec 'Pinning' do |pinning|
  pinning.dependency 'Hyperspace/Core'
  pinning.source_files = 'Sources/Certificate\ Pinning/**/*'
  end
end
