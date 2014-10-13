Pod::Spec.new do |s|
  s.name         = "Redefine"
  s.version      = "1.1.0"
  s.summary      = "iOS and OS X easy method swizzling - that is, method redefinitions at runtime"
  s.description  = <<-DESC
                   Redefine makes easier to achieve method swizzling - that is, to overwrite methods implementations during runtime using the objc runtime. It also makes possible to switch back and forth through implementations, the original and the new one.
                   The obvious use for it is unit tests. You don't have to prepare your code specifically for tests using factories, interfaces and etc, since it's possible to redefine any class or instance method. But, of course, you can do a lot of other crazy stuffs if you want to.
                   DESC
  s.homepage     = "https://github.com/danielalves/redefine"
  s.license      = "MIT"
  s.author       = "Daniel L. Alves"
  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.7"
  s.source       = { :git => "https://github.com/danielalves/redefine.git", :tag => s.version.to_s }
  s.source_files  = "Redefine"
  s.requires_arc = true
end
