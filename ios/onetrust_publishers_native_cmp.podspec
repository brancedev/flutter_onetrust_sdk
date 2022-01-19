#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint onetrust_publishers_native_cmp.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'onetrust_publishers_native_cmp'
  s.version          = '6.29.0.0'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://onetrust.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'OneTrust' => 'support@onetrust.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.dependency 'OneTrust-CMP-XCFramework', "~> #{s.version}"

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
