Pod::Spec.new do |s|
  s.name     = 'FacebookClient'
  s.version  = '1.0.3'
  s.license  = 'MIT'
  s.summary  = 'Talk to Facebook very easily.  Built on top of AFNetworking.'
  s.homepage = 'http://github.com/mrjjwright/FacebookClient'
  s.author   = { 'John Wright' => 'mrjjwright@gmail.com' }
  s.source   = { :git => 'http://github.com/mrjjwright/FacebookClient.git', :tag => '1.0.3' }
  s.source_files = 'FacebookClient'
  s.requires_arc = true
  s.dependency 'JSONKit', '~> 1.4'
  s.dependency 'FMDB',  '2.0'
  s.dependency 'AFNetworking', '~> 1.0RC1'
end
