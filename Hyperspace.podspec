#
# Be sure to run `pod lib lint Hyperspace.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Hyperspace'
  s.version          = '3.0.0'
  s.summary          = 'An extremely lightweight wrapper around URLSession to make working with APIs a breeze.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Hyperspace attempts to take the boilerplate out of working with HTTP in your app.
Unlike other networking libraries, the goal of Hyperspace is to keep things simple and maintain a minimal (but useful) feature set.
                       DESC

  s.homepage         = 'https://github.com/BottleRocketStudios/iOS-Hyperspace'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.author           = { 'Tyler Milner' => 'tyler.milner@bottlerocketstudios.com' }
  s.source           = { :git => 'https://github.com/BottleRocketStudios/iOS-Hyperspace.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.swift_version = '5.0'
  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
  core.source_files = 'Sources/Hyperspace/**/*'
  end

  s.subspec 'Futures' do |futures|
  futures.dependency 'BrightFutures', '~> 8.0.0'
  futures.dependency 'Hyperspace/Core'
  futures.source_files = 'Sources/Futures/**/*'
  end

  s.subspec 'Pinning' do |pinning|
  pinning.dependency 'Hyperspace/Core'
  pinning.source_files = 'Sources/Certificate\ Pinning/**/*'
  pinning.ios.deployment_target = '10.0'
  pinning.watchos.deployment_target = '3.0'
  pinning.tvos.deployment_target = '10.0'
  end
end
