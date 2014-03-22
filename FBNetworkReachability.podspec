Pod::Spec.new do |s|
  s.name         = "FBNetworkReachability"
  s.version      = "1.0.1"
  s.summary      = "Class to get network reachability on iOS device"
  s.description  = <<-DESC
Class to get network reachability on iOS device.
                   DESC
  s.homepage     = "https://github.com/dev5tec/FBNetworkReachability"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Hiroshi Hashiguchi" => "xcatsan@mac.com" }
  s.source       = { :git => "https://github.com/dev5tec/FBNetworkReachability.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Classes/*'

end
