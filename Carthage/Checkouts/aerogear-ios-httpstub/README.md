# aerogear-ios-httpstub [![Build Status](https://travis-ci.org/aerogear/aerogear-ios-httpstub.png)](https://travis-ci.org/aerogear/aerogear-ios-httpstub)

A small library inspired by [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs) to stub your network requests written in Swift.

> This module is beta software, it currently supports Xcode 6.1.1

## Example Usage

#### Initialize from an NSData

```swift
// set up http stub
StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
    return true
}, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
    return StubResponse(data:NSData.data(), statusCode: 200, headers: ["Content-Type" : "text/json"])
}))

// async test expectation
let registrationExpectation = expectationWithDescription("testStubWithNSURLSessionDefaultConfiguration");

let request = NSMutableURLRequest(URL: NSURL(string: "http://server.com"))

let config = NSURLSessionConfiguration.defaultSessionConfiguration()
let session = NSURLSession(configuration: config)

let task = session.dataTaskWithRequest(request) {(data, response, error) in
    XCTAssertNil(error, "unexpected error")
    XCTAssertNotNil(data, "response should contain data")
    
    registrationExpectation.fulfill()
}

task.resume()

waitForExpectationsWithTimeout(10, handler: nil)
```
#### Initialize from a file located in either a Bundle or a Documents Directory

```swift
// set up http stub from a stubbed file located in the test bundle
StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
    return true
}, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
     return StubResponse(filename: "mystubbedjson.json", location:.Bundle(NSBundle(forClass: AeroGearHttpStubTests.self)), statusCode: 200, headers: ["Content-Type" : "text/json"])
}))

// or
// set up http stub from a stubbed file located in the 'Documents' directory
StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
    return true
}, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
     return StubResponse(filename: "mystubbedjson.json", location:.Documents, statusCode: 200, headers: ["Content-Type" : "text/json"])
}))
```

## Adding the library to your project 
To add the library in your project, you can either use [Cocoapods](http://cocoapods.org) or manual install in your project. See the respective sections below for instructions:

### Using [Cocoapods](http://cocoapods.org)
At this time, Cocoapods support for Swift frameworks is supported in a [pre-release](http://blog.cocoapods.org/Pod-Authors-Guide-to-CocoaPods-Frameworks/). In your ```Podfile``` add:

```
pod 'AeroGearHttpStub'
```

and then:

```bash
pod install
```

to install your dependencies

### Manual Installation
Follow these steps to add the library in your Swift project:

1. Add AeroGearHttpStub as a [submodule](http://git-scm.com/docs/git-submodule) in your project. Open a terminal and navigate to your project directory. Then enter:
```bash
git submodule add https://github.com/aerogear/aerogear-ios-httpstub.git
```
2. Open the `aerogear-ios-httpstub` folder, and drag the `AeroGearHttpStub.xcodeproj` into the file navigator in Xcode.
3. In Xcode select your application target  and under the "Targets" heading section, ensure that the 'iOS  Deployment Target'  matches the application target of AeroGearHttpStub.framework (Currently set to 8.0).
5. Select the  "Build Phases"  heading section,  expand the "Target Dependencies" group and add  `AeroGearHttpStub.framework`.
7. Click on the `+` button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add `AeroGearHttpStub.framework`.

If you run into any problems, please [file an issue](http://issues.jboss.org/browse/AEROGEAR) and/or ask our [user mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-users). You can also join our [dev mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-dev).  
