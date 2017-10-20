@testable import Heimdallr
import Nimble
import Quick

class OAuthAccessTokenKeychainStoreSpec: QuickSpec {
    override func spec() {
        let accessToken = "01234567-89ab-cdef-0123-456789abcdef"
        let tokenType = "bearer"
        let expiresAt = Date(timeIntervalSince1970: 0)
        let refreshToken = "fedcba98-7654-3210-fedc-ba9876543210"

        var keychain = Keychain(service: "de.rheinfabrik.heimdallr.oauth.unit-tests")
        var store: OAuthAccessTokenKeychainStore!

        beforeEach {
            store = OAuthAccessTokenKeychainStore(service: "de.rheinfabrik.heimdallr.oauth.unit-tests")
        }
        
        // Since there is a bug with writing to the keychain within the iOS10 simulator we had to
        // disable some test until the bug is fixed by apple. Radar: https://openradar.appspot.com/27844971
        xdescribe("func storeAccessToken(accessToken: OAuthAccessToken?)") {
            let token = OAuthAccessToken(accessToken: accessToken, tokenType: tokenType, expiresAt: expiresAt, refreshToken: refreshToken)

            it("stores the access token, token type, expiration date, and refresh token in the keychain") {
                store.storeAccessToken(token)

                expect(keychain["access_token"]).to(equal(accessToken))
                expect(keychain["token_type"]).to(equal(tokenType))
                expect(keychain["expires_at"]).to(equal(expiresAt.timeIntervalSince1970.description))
                expect(keychain["refresh_token"]).to(equal(refreshToken))
            }

            context("when the access token does not have an expiration date") {
                let tokenWithoutExpirationDate = OAuthAccessToken(accessToken: accessToken, tokenType: tokenType, expiresAt: nil, refreshToken: refreshToken)

                it("removes the expiration date from the keychain") {
                    keychain["expires_at"] = expiresAt.description
                    store.storeAccessToken(tokenWithoutExpirationDate)
                    expect(keychain["expires_at"]).to(beNil())
                }
            }

            context("when the access token does not have a refresh token") {
                let tokenWithoutRefreshToken = OAuthAccessToken(accessToken: accessToken, tokenType: tokenType, expiresAt: expiresAt, refreshToken: nil)

                it("removes the refresh token date from the keychain") {
                    keychain["refresh_token"] = refreshToken
                    store.storeAccessToken(tokenWithoutRefreshToken)
                    expect(keychain["refresh_token"]).to(beNil())
                }
            }

            context("when the access token is nil") {
                it("removes the access token, token type, expiration date, and refresh token from the keychain") {
                    store.storeAccessToken(nil)

                    expect(keychain["access_token"]).to(beNil())
                    expect(keychain["token_type"]).to(beNil())
                    expect(keychain["expires_at"]).to(beNil())
                    expect(keychain["refresh_token"]).to(beNil())
                }
            }
        }

        xdescribe("func retrieveAccessToken() -> OAuthAccessToken?") {
            context("when the keychain contains an access token") {
                beforeEach {
                    keychain["access_token"] = accessToken
                    keychain["token_type"] = tokenType
                    keychain["expires_at"] = expiresAt.timeIntervalSince1970.description
                    keychain["refresh_token"] = refreshToken
                }

                it("retrieves and returns the access token from the keychain") {
                    let token = store.retrieveAccessToken()
                    expect(token).toNot(beNil())
                    expect(token?.accessToken).to(equal(accessToken))
                    expect(token?.tokenType).to(equal(tokenType))
                    expect(token?.expiresAt).to(equal(expiresAt))
                    expect(token?.refreshToken).to(equal(refreshToken))
                }

                context("without an expiration date") {
                    beforeEach {
                        keychain["expires_at"] = nil
                    }

                    it("returns an access token without expiration date") {
                        let token = store.retrieveAccessToken()
                        expect(token).toNot(beNil())
                        expect(token?.expiresAt).to(beNil())
                    }
                }

                context("without a refresh token") {
                    beforeEach {
                        keychain["refresh_token"] = nil
                    }

                    it("returns an access token without refresh token") {
                        let token = store.retrieveAccessToken()
                        expect(token).toNot(beNil())
                        expect(token?.refreshToken).to(beNil())
                    }
                }
            }

            context("when the keychain does not contain an access token") {
                beforeEach {
                    keychain["access_token"] = nil
                    keychain["token_type"] = nil
                    keychain["expires_at"] = nil
                    keychain["refresh_token"] = nil
                }

                it("returns nil") {
                    let token = store.retrieveAccessToken()
                    expect(token).to(beNil())
                }
            }
        }
    }
}
