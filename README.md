# <img src="https://cloud.githubusercontent.com/assets/460060/8159821/b8bfeb32-136a-11e5-83ed-83b7fe01df3a.jpg" width="30" height="30"> Heimdallr

Heimdallr is an [OAuth 2.0](https://tools.ietf.org/html/rfc6749) client specifically designed for easy usage. It currently supports the [resource owner password credentials grant](https://tools.ietf.org/html/rfc6749#section-4.3) flow, [refreshing an access token](https://tools.ietf.org/html/rfc6749#section-6), as well as [extension grants](https://tools.ietf.org/html/rfc6749#section-4.5).

If you are an Android Developer, please take a look at the [Android version of Heimdallr](https://github.com/trivago/Heimdall.droid).

[![Build Status](https://circleci.com/gh/trivago/Heimdallr.swift.svg?style=shield&circle-token=06d0c39133fae3dd9b649c116776c7f882885f1f)](https://circleci.com/gh/trivago/Heimdallr)

## Example

Before requesting an access token, the client must be configured appropriately:

```swift
let tokenURL = URL(string: "https://example.com/oauth/v2/token")!
let heimdallr = Heimdallr(tokenURL: tokenURL)
```

On login, the resource owner's password credentials are used to request an access token:

```swift
heimdallr.requestAccessToken(username: "johndoe", password: "A3ddj3w") { result in
    switch result {
    case .success:
        print("success")
    case .failure(let error):
        print("failure: \(error.localizedDescription)")
    }
}
```

Heimdallr automatically persists the access token. Afterwards, any `URLRequest` can be easily authenticated using the received access token:

```swift
var session: URLSession!
var request: URLRequest!

heimdallr.authenticateRequest(request) { result in
    switch result {
    case .success(let request):
        let task = session.dataTask(with: request) { data, response, error in
            // ...
        }
        
        task.resume()
    case .failure(let error):
        print("failure: \(error.localizedDescription)")
    }
}
```

## Installation

Installation is possible via Carthage or CocoaPods, see below for either method:

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a simple, decentralized dependency manager for Cocoa.

1. Add Heimdallr to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

  ```
  github "trivago/Heimdallr.swift" ~> 3.6.1
  ```

2. Run `carthage update` to fetch and build Heimdallr and its dependencies.

3. [Make sure your application's target links against `Heimdallr.framework` and copies all relevant frameworks into its application bundle (iOS); or embeds the binaries of all relevant frameworks (Mac).](https://github.com/carthage/carthage#getting-started)

Extensions for [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) are provided as `ReactiveHeimdallr.framework`.

### CocoaPods

1. Add Heimdallr to your [Podfile](https://guides.cocoapods.org/syntax/podfile.html):

   ```ruby
   pod 'Heimdallr', '~> 3.6.1'
   ```

2.  Run `pod install` to fetch and build Heimdallr and its dependencies.

Extensions for [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) are provided as `ReactiveCocoa` [subspec](https://guides.cocoapods.org/syntax/podfile.html#pod).

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

Heimdallr ships with an already built-in persistent keychain-based access token store. The service is configurable:

```swift
var service: String!

let accessTokenStore = OAuthAccessTokenKeychainStore(service: service)
```

### HeimdallrHTTPClient

An HTTP client that can be used by Heimdallr for requesting access tokens. It must implement the following `sendRequest` method:

```swift
protocol HeimdallrHTTPClient {
    func sendRequest(request: URLRequest, completion: (data: Data!, response: URLResponse!, error: Error?) -> ())
}
```

For convenience, a default HTTP client named `HeimdallrHTTPClientURLSession` and based on `URLSession` is provided. It may be configured with an `URLSession`:

```swift
var urlSession: URLSession!

let httpClient = HeimdallrHTTPClientURLSession(urlSession: session)
```

### OAuthAccessTokenParser

You can provide your own parser to handle the access token response of the server. It can be useful for parsing additional parameters sent in the response that your application may need. The parser must implement the following `parse` method:

```swift
protocol OAuthAccessTokenParser {
    func parse(data: Data) -> Result<OAuthAccessToken, Error>
}
```

### Heimdallr

Heimdallr must be initialized with the token endpoint URL and can optionally be configured with client credentials, an access token store and an HTTP client:

```swift
var tokenURL: URL!

let heimdallr = Heimdallr(tokenURL: tokenURL)
             // Heimdallr(tokenURL: tokenURL, credentials: credentials)
             // Heimdallr(tokenURL: tokenURL, credentials: credentials, accessTokenStore: accessTokenStore)
             // Heimdallr(tokenURL: tokenURL, credentials: credentials, accessTokenStore: accessTokenStore, accessTokenParser: accessTokenParser)
             // Heimdallr(tokenURL: tokenURL, credentials: credentials, accessTokenStore: accessTokenStore, accessTokenParser: accessTokenParser, httpClient: httpClient)
             // Heimdallr(tokenURL: tokenURL, credentials: credentials, accessTokenStore: accessTokenStore, accessTokenParser: accessTokenParser, httpClient: httpClient, resourceRequestAuthenticator: resourceRequestAuthenticator)
```

Whether the client's access token store currently holds an access token can be checked using the `hasAccessToken` property. *It's not checked whether the stored access token, if any, has already expired.*

The `authorize` method takes the resource owner's password credentials as parameters and uses them to request an access token from the token endpoint:

```swift
var username: String!
var password: String!

heimdallr.requestAccessToken(username: username, password: password) { result in
    // ...
}
```

*The `completion` closure may be invoked on any thread.*

Once successfully authorized, any `URLRequest` can be easily altered to include authentication via the received access token:

```swift
var request: URLRequest!

heimdallr.authenticateRequest(request) { result in
    // ...
}
```

If the access token has already expired and a refresh token is available, Heimdallr will automatically refresh the access token. *Refreshing requires network I/O.* *The `completion` closure may be invoked on any thread.*

### HeimdallrResourceRequestAuthenticator

By default, Heimdallr authenticates a request by setting the HTTP header field `Authorization`. This behavior can be changed by passing another resource request authenticator implementing `HeimdallrResourceRequestAuthenticator` to the initializer.

## About

Heimdallr was built by [trivago](http://www.trivago.com) 🏭

## Credits

Contains code for query string escaping taken from [Alamofire](https://github.com/Alamofire/Alamofire/) (MIT License)
