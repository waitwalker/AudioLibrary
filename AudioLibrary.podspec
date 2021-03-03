#
# Be sure to run `pod lib lint AudioLibrary.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AudioLibrary'
  s.version          = '1.0'
  s.summary          = 'A simple audio recording & playback component.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  A simple audio recording & playback component. Please refer to the sample use.
                       DESC

  s.homepage         = 'https://github.com/waitwalker/AudioLibrary'
  s.screenshots      = 'https://github.com/waitwalker/Resources/blob/master/Library/AudioLibrary/IMG_0261.PNG?raw=true', 'https://github.com/waitwalker/Resources/blob/master/Library/AudioLibrary/IMG_0263.PNG?raw=true'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'waitwalker' => 'waitwalker@163.com' }
  s.source           = { :git => 'https://github.com/waitwalker/AudioLibrary.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/waitwalkerme'

  s.ios.deployment_target = '10.2'
  s.swift_versions   = '5.0'

  s.source_files     = 'AudioLibrary/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AudioLibrary' => ['AudioLibrary/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'Toaster'

end
