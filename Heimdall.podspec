Pod::Spec.new do |spec|
  spec.name = 'Heimdall'
  spec.version = '2.0'
  spec.authors = {
    'Rheinfabrik' => 'hi@rheinfabrik.de'
  }
  spec.social_media_url = 'https://twitter.com/rheinfabrik'
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

  spec.dependency 'Argo', '~> 2.1'
  spec.dependency 'KeychainAccess', '~> 2.0'
  spec.dependency 'Result', '0.6.0-beta.4'
  spec.framework = 'Foundation'

  spec.source_files = 'Heimdall/**/*.{h,swift}'
end
