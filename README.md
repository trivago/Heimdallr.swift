# Heimdall

Heimdall is a [OAuth 2.0](https://tools.ietf.org/html/rfc6749) client specifically designed for easy usage. It currently only supports the [resource owner password credentials grant](https://tools.ietf.org/html/rfc6749#section-4.3) flow as well as [refreshing an access token](https://tools.ietf.org/html/rfc6749#section-6).

## Example

Before requesting an access token, the client must be configured appropriately:

```swift
let tokenURL = NSURL(string: "http://example.com/oauth/v2/token")!
let credentials = OAuthClientCredentials(id: "s6BhdRkqt3")
let accessTokenStore = OAuthAccessTokenKeychainStore(service: "com.example.app")

let heimdall = Heimdall(tokenURL: tokenURL, credentials: credentials, accessTokenStore: accessTokenStore)
```

On login, the resource owner's password credentials are used to request an access token:

```swift
heimdall.authorize("johndoe", "A3ddj3w") { result in
  switch result {
  case .Success:
    println("success")
  case .Failure(let error):
    println("failure") // use error.value
  }
}
```

Heimdall automatically persists the access token using the configured store. Afterwards, any `NSURLRequest` can be easily authenticated using the received access token:

```swift
var request: NSURLRequest!

heimdall.requestByAddingAuthorizationToRequest(request) { result
  switch result {
  case .Success(let request):
    println("success") // use request.value
  case .Failure(let error):
    println("failure") // use error.value
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
  github "rheinfabrik/Heimdall.swift"
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
public protocol OAuthAccessTokenStore {
  func storeAccessToken(accessToken: OAuthAccessToken?)
  func retrieveAccessToken() -> OAuthAccessToken?
}
```

Heimdall ships with an already built-in persistent Keychain-based access token store, using [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess). The service is configurable:

```swift
var service: String!

let accessTokenStore = OAuthAccessTokenKeychainStore(service: service)
```

### Heimdall

Heimdall must be initialized with the token endpoint URL and can optionally be configured with client credentials and an access token store:

```swift
var tokenURL: NSURL!

let heimdall = Heimdall(tokenURL: tokenURL)
            // Heimdall(tokenURL: tokenURL, credentials: credentials)
            // Heimdall(tokenURL: tokenURL, credentials: credentials, accessTokenStore: accessTokenStore)
```

Whether the client's access token store currently holds an access token can be checked using the `hasAccessToken` property. *It's not checked whether the stored access token, if any, has already expired.*

The `authorize` method takes the resource owner's password credentials as parameters and uses them to request an access token from the token endpoint:

```swift
var username: String!
var password: String!

heimdall.authorize(username, password) { result in
  // ...
}
```

*The `completion` closure may be invoked on any thread.*

Once successfully authorized, any `NSURLRequest` can be easily altered to include authentication via the received access token:

```swift
var request: NSURLRequest!

heimdall.requestByAddingAuthorizationToRequest(request) { result
  // ...
}
```

If the access token has already expired and a refresh token is available, Heimdall will automatically refresh the access token. *Refreshing requires network I/O.* *The `completion` closure may be invoked on any thread.*

## About

Heimdall was built by [Rheinfabrik](http://www.rheinfabrik.de) 🏭
