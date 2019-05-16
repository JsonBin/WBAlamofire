Pod::Spec.new do |s|
  s.name         = 'WBAlamofire'
  s.version      = '2.0.0'
  s.license      = 'MIT' 
  s.summary      = 'Extend Alamofire, add the cache to result.'
  s.homepage     = 'https://github.com/JsonBin/WBAlamofire'
  s.authors      = { 'JsonBin' => 'enjoy_bin@163.com' }
  s.source = { :git => 'https://github.com/JsonBin/WBAlamofire.git', :tag => s.version }
  s.requires_arc = true

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.swift_version = '5.0'

  s.source_files  =  'Source/*.swift'  

  s.dependency 'Alamofire'
end
