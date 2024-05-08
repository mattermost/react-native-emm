require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-emm"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "12.4" }
  s.source       = { :git => "https://github.com/mattermost/react-native-emm.git", :tag => "#{s.version}" }
  s.swift_version = '5.0'

  
  s.source_files = "ios/**/*.{h,m,mm,swift}"
  
  fabric_enabled = ENV["RCT_NEW_ARCH_ENABLED"] == "1"

  if fabric_enabled
    s.pod_target_xcconfig    = {
      "DEFINES_MODULE" => "YES",
      "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES",
      "OTHER_CPLUSPLUSFLAGS" => "-DRCT_NEW_ARCH_ENABLED=1",
      "OTHER_SWIFT_FLAGS" => "-no-verify-emitted-module-interface"
    }
  else
    s.pod_target_xcconfig    = {
      "DEFINES_MODULE" => "YES",
      "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES",
      "OTHER_SWIFT_FLAGS" => "-no-verify-emitted-module-interface"
    }
  end

  install_modules_dependencies(s)

end
