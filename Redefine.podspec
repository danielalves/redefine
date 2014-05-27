Pod::Spec.new do |s|
  s.name         = "Redefine"
  s.version      = "1.0.5"
  s.summary      = "Redefine makes easier to overwrite methods implementations during runtime using the objc runtime."
  s.homepage     = "https://github.com/danielalves/redefine"
  s.license      = "MIT"
  s.author       = "Daniel L. Alves"
  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.7"
  s.source       = { :git => "https://github.com/danielalves/redefine.git", :tag => s.version.to_s }
  s.source_files  = "Redefine"
  s.requires_arc = true
end
