import Foundation
import Heimdallr
import XCTest

final class OAuthAccessTokenTests: XCTestCase {
    let accessToken = OAuthAccessToken(accessToken: "accessToken",
                                         tokenType: "tokenType",
                                         expiresAt: Date(timeIntervalSince1970: 0),
                                      refreshToken: "refreshToken")
    
    func testCallingCopyReturnsAnAccessToken() {
        let result: OAuthAccessToken = accessToken.copy()
        XCTAssertNotEqual(result, accessToken, "Access tokens should not be equal")
    }
    
    func testSettingANewAccessTokenWithCorrectData() {
        let result = accessToken.copy(accessToken: "accessToken2")
        XCTAssertEqual(result.accessToken, "accessToken2", "New access token was not set correctly")
        XCTAssertEqual(result.tokenType, accessToken.tokenType, "The token type was not copied over")
        XCTAssertEqual(result.expiresAt, accessToken.expiresAt, "The expiration date was not copied over")
        XCTAssertEqual(result.refreshToken, accessToken.refreshToken, "The refresh token was not copied over")
    }
    
    func testUpdatingTheTokenType() {
        let result = accessToken.copy(tokenType: "tokenType2")
        
        XCTAssertEqual(result.accessToken, accessToken.accessToken, "The access token was not copied over")
        XCTAssertEqual(result.tokenType, "tokenType2", "The new token type was not set correctly")
        XCTAssertEqual(result.expiresAt, accessToken.expiresAt, "The expiration date was not copied over")
        XCTAssertEqual(result.refreshToken, accessToken.refreshToken, "The refresh token was not copied over")
    }
    
    func testUpdatingTheExpirationDate() {
        let result = accessToken.copy(expiresAt: Date(timeIntervalSince1970: 1))
        
        XCTAssertEqual(result.accessToken, accessToken.accessToken, "The access token was not copied over")
        XCTAssertEqual(result.tokenType, accessToken.tokenType, "The token type was not copied over")
        XCTAssertEqual(result.expiresAt, Date(timeIntervalSince1970: 1), "The new expiration date was not set correctly")
        XCTAssertEqual(result.refreshToken, accessToken.refreshToken, "The refresh token was not copied over")
    }
    
    func testUpdatingTheRefreshToken() {
        let result = accessToken.copy(refreshToken: "refreshToken2")
        
        XCTAssertEqual(result.accessToken, accessToken.accessToken, "The access token was not copied over")
        XCTAssertEqual(result.tokenType, accessToken.tokenType, "The token type was not copied over")
        XCTAssertEqual(result.expiresAt, accessToken.expiresAt, "The expiration date was not copied over")
        XCTAssertEqual(result.refreshToken, "refreshToken2", "The new refresh token was not set correctly")
    }
}
