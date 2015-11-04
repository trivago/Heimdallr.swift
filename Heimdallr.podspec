Pod::Spec.new do |spec|
  spec.name = 'Heimdallr'
  spec.version = '3.0'
  spec.authors = {
    'Rheinfabrik' => 'hi@rheinfabrik.de'
  }
  spec.social_media_url = 'https://twitter.com/rheinfabrik'
  spec.license = {
    :type => 'Apache License, Version 2.0',
    :file => 'LICENSE'
  }
  spec.homepage = 'https://github.com/rheinfabrik/Heimdallr.swift'
  spec.source = {
    :git => 'https://github.com/rheinfabrik/Heimdallr.swift.git',
    :tag => spec.version.to_s
  }
  spec.summary = 'Easy to use OAuth 2 library, written in Swift'
  spec.description = 'Heimdallr is an OAuth 2.0 client specifically designed for easy usage. It currently supports the resource owner password credentials grant flow, refreshing an access token as well as extension grants.'

  spec.ios.deployment_target = '8.0'
  spec.osx.deployment_target = '10.10'

  spec.default_subspec = 'Core'

  spec.subspec 'Core' do |subspec|
    subspec.dependency 'Result', '0.6.0-beta.4'
    subspec.dependency 'Argo', '2.1.0'
    subspec.dependency 'KeychainAccess', '2.2.0'
    subspec.framework = 'Foundation'

    subspec.source_files = 'Heimdallr/Core/*.swift'
  end

  spec.subspec 'ReactiveCocoa' do |subspec|
    subspec.dependency 'Heimdallr/Core'
    subspec.dependency 'ReactiveCocoa', '4.0.0-alpha-1'

    subspec.source_files = 'Heimdallr/ReactiveCocoa/*.swift'
  end
end
