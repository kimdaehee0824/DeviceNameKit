Pod::Spec.new do |spec|
  spec.name         = "DeviceNameKit"
  spec.version      = "0.0.1"
  spec.summary      = "A library for fetching device names based on model identifiers."
  spec.description  = "DeviceNameKit provides a simple way to retrieve human-readable device names from device model identifiers."
  spec.homepage     = "https://github.com/kimdaehee0824/DeviceNameKit"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Your Name" => "kimdaehee.public@gmail.com" }
  spec.source       = { :git => "https://github.com/kimdaehee0824/DeviceNameKit.git", :tag => "#{spec.version}" }

  spec.swift_version = "5.9"
  spec.platforms = {
    :ios => "13.0",
    :macos => "11.0",
    :watchos => "6.0",
    :tvos => "13.0",
    :visionos => "1.0"
  }

  spec.source_files = "Sources/DeviceNameKit/**/*.{swift}"

  spec.pod_target_xcconfig = { 'MACOSX_DEPLOYMENT_TARGET' => '11.0' }
  spec.user_target_xcconfig = { 'MACOSX_DEPLOYMENT_TARGET' => '11.0' }

  spec.frameworks = "Foundation"
  spec.requires_arc = true
end
