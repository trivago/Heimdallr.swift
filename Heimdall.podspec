Pod::Spec.new do |spec|
  spec.name = 'Heimdall'
  spec.version = '2.0-alpha.1'
  spec.authors = {
    'Felix Jendrusch' => 'felix@rheinfabrik.de',
    'Tim Brückmann' => 'tim@rheinfabrik.de'
  }
  spec.license = {
    :type => 'Apache License, Version 2.0',
    :file => 'LICENSE'
  }
  spec.homepage = 'https://github.com/rheinfabrik/Heimdall.swift'
  spec.source = {
    :git => 'https://github.com/rheinfabrik/Heimdall.swift.git',
    :branch => 'feature/swift-2.0'
  }
  spec.summary = 'Easy to use OAuth 2 library for iOS, written in Swift'
  spec.description = 'Heimdall is an OAuth 2.0 client specifically designed for easy usage. It currently supports the resource owner password credentials grant flow, refreshing an access token as well as extension grants.'

  spec.platform = :ios, '8.0'

  spec.dependency 'Argo', '~> 1.0'
  spec.dependency 'KeychainAccess', '~> 1.2'
  spec.dependency 'Result', '0.6-beta.1'
  spec.framework = 'Foundation'

  spec.source_files = 'Heimdall/**/*.{h,swift}'
end
