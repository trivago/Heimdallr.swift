# Heimdall

Heimdall is an [OAuth 2.0](https://tools.ietf.org/html/rfc6749) client specifically designed for easy usage. It currently only supports the [resource owner password credentials grant](https://tools.ietf.org/html/rfc6749#section-4.3) flow as well as [refreshing an access token](https://tools.ietf.org/html/rfc6749#section-6).

If you are familiar with [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa), also check out [ReactiveHeimdall](https://github.com/rheinfabrik/ReactiveHeimdall)!

## Example

Before requesting an access token, the client must be configured appropriately:

```swift
let tokenURL = NSURL(string: "http://example.com/oauth/v2/token")!

let heimdall = Heimdall(tokenURL: tokenURL)
```

On login, the resource owner's password credentials are used to request an access token:

```swift
heimdall.requestAccessToken("johndoe", "A3ddj3w") { result in
    switch result {
    case .Success:
        println("success")
    case .Failure(let error):
        println("failure: \(error.unbox.localizedDescription)")
    }
}
```

Heimdall automatically persists the access token. Afterwards, any `NSURLRequest` can be easily authenticated using the received access token:

```swift
var session: NSURLSession!
var request: NSURLRequest!

heimdall.authenticateRequest(request) { result
    switch result {
    case .Success(let request):
        let task = session.dataTaskWithRequest(request.unbox) { data, response, error in
            // ...
        }

        task.resume()
    case .Failure(let error):
        println("failure: \(error.unbox.localizedDescription)")
    }
}
```

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a simple, decentralized dependency manager for Cocoa. You can install it with [Homebrew](http://brew.sh) using the following commands:

```
$ brew update
$ brew install carthage
```

1. Add Heimdall to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):
  ```
  github "rheinfabrik/Heimdall.swift" ~> 1.0
  ```

2. Run `carthage update` to actually fetch Heimdall and its dependencies.

3. On your application target's "General" settings tab, in the "Linked Frameworks and Libraries" section, add `Heimdall.framework` from the [Carthage/Build](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#carthagebuild) folder on disk.

4. On your application target's "Build Phases" settings tab, click the "+" icon and choose "New Run Script Phase". Create a Run Script with the following contents:
  ```
  /usr/local/bin/carthage copy-frameworks
  ```
  and add the paths to all relevant frameworks under "Input Files":
  ```
  $(SRCROOT)/Carthage/Build/iOS/LlamaKit.framework
  $(SRCROOT)/Carthage/Build/iOS/Runes.framework
  $(SRCROOT)/Carthage/Build/iOS/Argo.framework
  $(SRCROOT)/Carthage/Build/iOS/KeychainAccess.framework
  $(SRCROOT)/Carthage/Build/iOS/Heimdall.framework
  ```
  This script works around an [App Store submission bug](http://www.openradar.me/radar?id=6409498411401216) triggered by universal binaries.

## Usage

### OAuthClientCredentials

The client credentials, consisting of the client's identifier and optionally its secret, are used for authenticating with the token endpoint:

```swift
var identifier: String!
var secret: String!

let credentials = OAuthClientCredentials(id: identifier)
               // OAuthClientCredentials(id: identifier, secret: secret)
```

*Please note that native applications are considered to be [public clients](https://tools.ietf.org/html/rfc6749#section-2.1).*

### OAuthAccessTokenStore

An access token store is used to (persistently) store an access token received from the token endpoint. It must implement the following storage and retrieval methods:

```swift
protocol OAuthAccessTokenStore {
    func storeAccessToken(accessToken: OAuthAccessToken?)
    func retrieveAccessToken() -> OAuthAccessToken?
}
```

Heimdall ships with an already built-in persistent Keychain-based access token store, using [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess). The service is configurable:

```swift
var service: String!

let accessTokenStore = OAuthAccessTokenKeychainStore(service: service)
```

### HeimdallHTTPClient

An HTTP client that can be used by Heimdall for requesting access tokens. It must implement the following `sendRequest` method:

```swift
protocol HeimdallHTTPClient {
    func sendRequest(request: NSURLRequest, completion: (data: NSData!, response: NSURLResponse!, error: NSError?) -> ())
}
```

For convenience, a default HTTP client named `HeimdallHTTPClientNSURLSession` and based on `NSURLSession` is provided. It may be configured with an `NSURLSession`:

```swift
var urlSession: NSURLSession!

let httpClient = HeimdallHTTPClientNSURLSession(urlSession: session)
```

### Heimdall

Heimdall must be initialized with the token endpoint URL and can optionally be configured with client credentials, an access token store and an HTTP client:

```swift
var tokenURL: NSURL!

let heimdall = Heimdall(tokenURL: tokenURL)
            // Heimdall(tokenURL: tokenURL, credentials: credentials)
            // Heimdall(tokenURL: tokenURL, credentials: credentials, accessTokenStore: accessTokenStore)
            // Heimdall(tokenURL: tokenURL, credentials: credentials, accessTokenStore: accessTokenStore, httpClient: httpClient)
```

Whether the client's access token store currently holds an access token can be checked using the `hasAccessToken` property. *It's not checked whether the stored access token, if any, has already expired.*

The `authorize` method takes the resource owner's password credentials as parameters and uses them to request an access token from the token endpoint:

```swift
var username: String!
var password: String!

heimdall.requestAccessToken(username, password) { result in
    // ...
}
```

*The `completion` closure may be invoked on any thread.*

Once successfully authorized, any `NSURLRequest` can be easily altered to include authentication via the received access token:

```swift
var request: NSURLRequest!

heimdall.authenticateRequest(request) { result
    // ...
}
```

If the access token has already expired and a refresh token is available, Heimdall will automatically refresh the access token. *Refreshing requires network I/O.* *The `completion` closure may be invoked on any thread.*

## About

Heimdall was built by [Rheinfabrik](http://www.rheinfabrik.de) 🏭
