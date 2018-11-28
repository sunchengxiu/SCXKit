#
#  Be sure to run `pod spec lint SCXKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "SCXKit"
  s.version      = "0.0.1"
  s.summary      = "imitation YYKit"

  s.homepage     = "https://github.com/sunchengxiu?tab=repositories"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "孙承秀" => "15699998823@163.com" }


  s.source       = { :git => "https://github.com/sunchengxiu/SCXKit.git", :tag => "v1.0.0" }

  s.ios.deployment_target = '7.0'

  # s.subspec 'SCXModel' do |model|
  #   model.source_files = 'RCModel/**/*.{h,m}'
  # end

  s.subspec 'SCXCahce' do |rcCache|
    rcCache.source_files = 'RCCache/**/*.{h,m}'
  end

  # s.subspec 'SCXQueue' do |rcQueue|
  #   rcQueue.source_files = 'RCQueue/**/*.{h,m}'
  # end

end
