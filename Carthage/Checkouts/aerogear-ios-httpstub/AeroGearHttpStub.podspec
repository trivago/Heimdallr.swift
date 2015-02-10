Pod::Spec.new do |s|
  s.name         = "AeroGearHttpStub"
  s.version      = "0.2.0"
  s.summary      = "A small library to stub your network requests with dynamic dependency injection written in Swift"
  s.homepage     = "https://github.com/aerogear/aerogear-ios-httpstub"
  s.license      =  "Apache License, Version 2.0"
  s.author       = "Red Hat, Inc."
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/aerogear/aerogear-ios-httpstub.git", :tag => s.version }
  s.source_files = 'AeroGearHttpStub/*.{swift}'
  s.framework  = "Foundation"
  s.requires_arc = true  
end
