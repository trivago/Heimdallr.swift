import Foundation
import Heimdallr
import XCTest

final class HeimdallResourceRequestAuthenticatorHTTPAuthorizationHeaderTests: XCTestCase {
    func testAuthorizationHeaderIsSet() {
        let resourceAuthenticator: HeimdallResourceRequestAuthenticatorHTTPAuthorizationHeader = HeimdallResourceRequestAuthenticatorHTTPAuthorizationHeader()
        let urlRequest = URLRequest(url: URL(string: "http://www.rheinfabrik.de")!)
        let accessToken = OAuthAccessToken(accessToken: "MTQzM2U3YTI3YmQyOWQ5YzQ0NjY4YTZkYjM0MjczYmZhNWI1M2YxM2Y1MjgwYTg3NDk3ZDc4ZGUzM2YxZmJjZQ", tokenType: "Bearer")
        let authenticatedRequest = resourceAuthenticator.authenticateResourceRequest(urlRequest, accessToken: accessToken)
        let authorizationHeaderValue = authenticatedRequest.value(forHTTPHeaderField: "Authorization")
        
        XCTAssertEqual(authorizationHeaderValue,
                       "Bearer MTQzM2U3YTI3YmQyOWQ5YzQ0NjY4YTZkYjM0MjczYmZhNWI1M2YxM2Y1MjgwYTg3NDk3ZDc4ZGUzM2YxZmJjZQ",
                       "Invalid authorization header value")
    }
}
