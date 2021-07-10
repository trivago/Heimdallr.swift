import Foundation
import Heimdallr
import XCTest

class HTTPAuthenticationTests: XCTestCase {

    func testBasicAuthenticationMatches() {
        let lhs: HTTPAuthentication = .basicAuthentication(username: "username", password: "password")
        let rhs: HTTPAuthentication = .basicAuthentication(username: "username", password: "password")

        XCTAssertEqual(lhs, rhs, "Expected username and password to match")
    }

    func testBasicAuthenticationUsernameDoesNotMatch() {
        let lhs: HTTPAuthentication = .basicAuthentication(username: "usernamea", password: "password")
        let rhs: HTTPAuthentication = .basicAuthentication(username: "usernameb", password: "password")

        XCTAssertNotEqual(lhs, rhs, "Expected username to match")
    }

    func testBasicAuthenticationPasswordDoesNotMatch() {
        let lhs: HTTPAuthentication = .basicAuthentication(username: "username", password: "passworda")
        let rhs: HTTPAuthentication = .basicAuthentication(username: "username", password: "passwordb")

        XCTAssertNotEqual(lhs, rhs, "Expected password to match")
    }

    func testAccessTokenAuthenticationMatches() {
        let lhs: HTTPAuthentication = .accessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType"))
        let rhs: HTTPAuthentication = .accessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType"))

        XCTAssertEqual(lhs, rhs, "Expected access token and token type to match")
    }

    func testAccessTokenAuthenticationAccessTokenDoesNotMatch() {
        let lhs: HTTPAuthentication = .accessTokenAuthentication(OAuthAccessToken(accessToken: "accessTokena", tokenType: "tokenType"))
        let rhs: HTTPAuthentication = .accessTokenAuthentication(OAuthAccessToken(accessToken: "accessTokenb", tokenType: "tokenType"))

        XCTAssertNotEqual(lhs, rhs, "Expected access token to match")
    }

    func testAccessTokenAuthenticationTokenTypeDoesNotMatch() {
        let lhs: HTTPAuthentication = .accessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenTypea"))
        let rhs: HTTPAuthentication = .accessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenTypeb"))

        XCTAssertNotEqual(lhs, rhs, "Expected token type to match")
    }

    func testAuthenticationMethodsDoNotMatch() {
        let lhs: HTTPAuthentication = .basicAuthentication(username: "username", password: "password")
        let rhs: HTTPAuthentication = .accessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType"))

        XCTAssertNotEqual(lhs, rhs, "Mixed authentication methods should not be equal")
    }
}

class URLRequestExtensionsTests: XCTestCase {
    var urlRequest: URLRequest!

    override func setUp() {
        urlRequest = URLRequest(url: URL(string: "https://accounts.example.com")!)
    }

    override func tearDown() {
        urlRequest = nil
    }

    func testAuthorizationHeaderIsNilWhenNotSet() {
        XCTAssertNil(urlRequest.HTTPAuthorization, "Expected authorization to be nil")
    }

    func testAuthorizationHeaderHasValueIfSet() {
        urlRequest.setValue("Basic dXNlcm5hbWU6cGFzc3dvcmQ=", forHTTPHeaderField: "Authorization")

        XCTAssertEqual(urlRequest.HTTPAuthorization, "Basic dXNlcm5hbWU6cGFzc3dvcmQ=", "Authorization header does not equal expected value")
    }

    func testSettingAuthorizationHeaderToNil() {
        urlRequest.setValue("Basic dXNlcm5hbWU6cGFzc3dvcmQ=", forHTTPHeaderField: "Authorization")
        urlRequest.setHTTPAuthorization(nil)

        XCTAssertNil(urlRequest.HTTPAuthorization, "Expected authorization header to be nil")
    }

    func testCallingSetHTTPAuthorizationSetsTheHeader() {
        urlRequest.setHTTPAuthorization("Basic dXNlcm5hbWU6cGFzc3dvcmQ=")

        XCTAssertEqual(urlRequest.HTTPAuthorization, "Basic dXNlcm5hbWU6cGFzc3dvcmQ=", "Authorization header does not equal expected value")
    }

    func testCallingSetHTTPAuthorizationWithBasicAuthentication() {
        let authentication: HTTPAuthentication = .basicAuthentication(username: "username", password: "password")
        urlRequest.setHTTPAuthorization(authentication)

        XCTAssertEqual(urlRequest.HTTPAuthorization, "Basic dXNlcm5hbWU6cGFzc3dvcmQ=", "Expected authorization to be basic authentication")
    }

    func testCallSetHTTPAuthorizationWithAccessTokenAuthentication() {
        let authentication: HTTPAuthentication = .accessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType"))
        urlRequest.setHTTPAuthorization(authentication)

        XCTAssertEqual(urlRequest.HTTPAuthorization, "tokenType accessToken", "Expected authorization to be access token")
    }

    func testSettingHTTPBodyWithNil() {
        urlRequest.setHTTPBody(parameters: nil)

        XCTAssertNil(urlRequest.httpBody, "Expected HTTP body to be nil")
    }

    func testSettingHTTPBodyWithParametersContainsTheCorrectValues() throws {
        let parameters: [String: AnyObject] = [
            "#key1": "%value1" as AnyObject,
            "#key2": "%value2" as AnyObject,
            "key3": "value3[]" as AnyObject,
            "key4": ":&=;+!@#$()',*" as AnyObject,
            "key5.": "value.5" as AnyObject,
            "key6": "https://accounts.example.com/oauth/v2/foo/bar" as AnyObject,
            "key7": [
                "one",
                "two"
            ] as AnyObject,
            "key8": [
                "subkeyOne": "one",
                "subkeyTwo": "two"
            ] as AnyObject
        ]
        urlRequest.setHTTPBody(parameters: parameters)

        let httpBody = try XCTUnwrap(urlRequest.httpBody, "Expected HTTP body to not be nil")
        let components = String(data: httpBody, encoding: .utf8)?
            .components(separatedBy: "&")
            .sorted { $0 < $1 }

        XCTAssertEqual(components?[0], "%23key1=%25value1")
        XCTAssertEqual(components?[1], "%23key2=%25value2")
        XCTAssertEqual(components?[2], "key3=value3%5B%5D")
        XCTAssertEqual(components?[3], "key4=%3A%26%3D%3B%2B%21%40%23%24%28%29%27%2C%2A")
        XCTAssertEqual(components?[4], "key5.=value.5")
        XCTAssertEqual(components?[5], "key6=https%3A//accounts.example.com/oauth/v2/foo/bar")
        XCTAssertEqual(components?[6], "key7%5B%5D=one")
        XCTAssertEqual(components?[7], "key7%5B%5D=two")
    }
}
