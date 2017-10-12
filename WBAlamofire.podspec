Pod::Spec.new do |s|

  s.name         = 'WBAlamofire'
  s.version      = '1.0.0'
  s.summary      = 'Extend Alamofire, add the cache to result.'
  s.description  = 'Inherited from Alamofire, each API as a class, the result of the data cache'
  s.homepage     = 'https://github.com/JsonBin/WBAlamofire'
  s.license      = 'MIT'
  s.author       = { 'JsonBin' => '1120508748@qq.com' }
  # s.social_media_url   = 'http://twitter.com/JsonBin'

  s.framework    = 'UIKit'
  s.platform = :ios, '9.0'
  s.ios.deployment_target = '8.0'

  s.source = { :git => 'https://github.com/JsonBin/WBAlamofire.git', :tag => s.version }

  s.source_files  =  'Source/*.swift'
  s.requires_arc = true
  s.dependency "Alamofire"

end
