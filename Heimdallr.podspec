Pod::Spec.new do |spec|
  spec.name = "Heimdallr"
  spec.version = "4.0.0"
  spec.authors = {
    "trivago" => "info@trivago.de"
  }
  spec.social_media_url = "https://twitter.com/trivago"
  spec.license = {
    :type => "Apache License, Version 2.0",
    :file => "LICENSE"
  }
  spec.homepage = "https://github.com/trivago/Heimdallr.swift"
  spec.source = {
    :git => "https://github.com/trivago/Heimdallr.swift.git",
    :tag => spec.version.to_s
  }
  
  spec.summary = "Easy to use OAuth 2 library, written in Swift"
  spec.description = "Heimdallr is an OAuth 2.0 client specifically designed for easy usage. It currently supports the resource owner password credentials grant flow, refreshing an access token as well as extension grants."

  spec.platforms = { :ios => "11.0", :osx => "10.10" }
  spec.swift_version = "5.3"
  
  spec.source_files = "Sources/Heimdallr/*.swift"
end
