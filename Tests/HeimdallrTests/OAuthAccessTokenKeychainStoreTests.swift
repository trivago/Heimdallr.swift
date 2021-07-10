import Foundation
@testable import Heimdallr
import XCTest

class OAuthAccessTokenKeychainStoreMock: OAuthAccessTokenStore {
    var keychain: [String: String] = [:]
    
    func storeAccessToken(_ accessToken: OAuthAccessToken?) {
        keychain["access_token"] = accessToken?.accessToken
        keychain["token_type"] = accessToken?.tokenType
        keychain["expires_at"] = accessToken?.expiresAt?.timeIntervalSince1970.description
        keychain["refresh_token"] = accessToken?.refreshToken
    }

    func retrieveAccessToken() -> OAuthAccessToken? {
        let accessToken = keychain["access_token"]
        let tokenType = keychain["token_type"]
        let refreshToken = keychain["refresh_token"]
        let expiresAt = keychain["expires_at"].flatMap { description in
            return Double(description).flatMap { expiresAtInSeconds in
                Date(timeIntervalSince1970: expiresAtInSeconds)
            }
        }

        if let accessToken = accessToken, let tokenType = tokenType {
            return OAuthAccessToken(accessToken: accessToken, tokenType: tokenType, expiresAt: expiresAt, refreshToken: refreshToken)
        }

        return nil
    }
}

final class OAuthAccessTokenKeychainStoreTests: XCTestCase {
    let accessToken = "01234567-89ab-cdef-0123-456789abcdef"
    let tokenType = "bearer"
    let expiresAt = Date(timeIntervalSince1970: 0)
    let refreshToken = "fedcba98-7654-3210-fedc-ba9876543210"
    var storeMock: OAuthAccessTokenKeychainStoreMock!

    override func setUp() {
        storeMock = OAuthAccessTokenKeychainStoreMock()
    }

    override func tearDown() {
        storeMock = nil
    }

    func testAccessTokenDataIsStoredInTheKeychain() {
        let token = OAuthAccessToken(accessToken: accessToken, tokenType: tokenType, expiresAt: expiresAt, refreshToken: refreshToken)
        storeMock.storeAccessToken(token)

        XCTAssertEqual(storeMock.keychain["access_token"], accessToken, "Expected access token")
        XCTAssertEqual(storeMock.keychain["token_type"], tokenType, "Expected token type")
        XCTAssertEqual(storeMock.keychain["expires_at"], expiresAt.timeIntervalSince1970.description, "Expected correct expiration date")
        XCTAssertEqual(storeMock.keychain["refresh_token"], refreshToken, "Expected refresh token")
    }

    func testAccessTokenIsRetrievedFromTheKeychain() {
        let token = OAuthAccessToken(accessToken: accessToken, tokenType: tokenType, expiresAt: expiresAt, refreshToken: refreshToken)
        storeMock.storeAccessToken(token)
        let accessToken = storeMock.retrieveAccessToken()

        XCTAssertEqual(accessToken?.accessToken, token.accessToken, "Access token does not match")
        XCTAssertEqual(accessToken?.tokenType, token.tokenType, "Token type does not match")
        XCTAssertEqual(accessToken?.expiresAt?.timeIntervalSince1970.description, token.expiresAt?.timeIntervalSince1970.description, "Expiration date does not match")
        XCTAssertEqual(accessToken?.refreshToken, token.refreshToken, "Refresh token does not match")
    }
}
