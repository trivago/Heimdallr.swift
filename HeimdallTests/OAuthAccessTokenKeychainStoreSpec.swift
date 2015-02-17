import Heimdall
import KeychainAccess
import Nimble
import Quick

class OAuthAccessTokenKeychainStoreSpec: QuickSpec {
    override func spec() {
        var store: OAuthAccessTokenKeychainStore!
        let keychain = Keychain(service: "de.rheinfabrik.heimdall.oauth.unit-tests")
        
        beforeEach {
            store = OAuthAccessTokenKeychainStore(service: "de.rheinfabrik.heimdall.oauth.unit-tests")
        }
        
        describe("-storeAccessToken") {
            let expirationDate = NSDate().dateByAddingTimeInterval(3600)
            let token = OAuthAccessToken(
                accessToken: "01234567-89ab-cdef-0123-456789abcdef",
                tokenType: "bearer",
                expiresAt: expirationDate,
                refreshToken: "127386523686")
            
            beforeEach {
                store.storeAccessToken(token)
            }
            
            it("saves the access token to the keychain") {
                expect(keychain["access_token"]).to(equal("01234567-89ab-cdef-0123-456789abcdef"))
            }
            
            it("saves the access token type to the keychain") {
                expect(keychain["token_type"]).to(equal("bearer"))
            }
            
            it("saves the access token expiration date to the keychain if present") {
                expect(keychain["expires_at"]).to(equal(expirationDate.timeIntervalSince1970.description))
            }
            
            it("saves the access token refresh token to the keychain if present") {
                expect(keychain["refresh_token"]).to(equal("127386523686"))
            }
            
            context("when the access token does not have an expiration date") {
                it("clears the expiration date from the keychain") {
                    keychain["expires_at"] = "foobar"
                    let tokenWithoutExpirationDate = OAuthAccessToken(
                        accessToken: "01234567-89ab-cdef-0123-456789abcdef",
                        tokenType: "bearer",
                        expiresAt: nil,
                        refreshToken: "127386523686")
                    store.storeAccessToken(tokenWithoutExpirationDate)
                    expect(keychain["expires_at"]).to(beNil())
                }
            }
            
            context("when the access token does not have a refresh token") {
                it("clears the refresh token date from the keychain") {
                    keychain["refresh_token"] = "foobar"
                    let tokenWithoutRefreshToken = OAuthAccessToken(
                        accessToken: "01234567-89ab-cdef-0123-456789abcdef",
                        tokenType: "bearer",
                        expiresAt: expirationDate,
                        refreshToken: nil)
                    store.storeAccessToken(tokenWithoutRefreshToken)
                    expect(keychain["refresh_token"]).to(beNil())
                }
            }
            
            context("when the access token is nil") {
                it("clears the keychain") {
                    store.storeAccessToken(nil)
                    
                    expect(keychain["access_token"]).to(beNil())
                    expect(keychain["token_type"]).to(beNil())
                    expect(keychain["expires_at"]).to(beNil())
                    expect(keychain["refresh_token"]).to(beNil())
                }
            }
        }
        
        describe("-retrieveAccessToken") {
            context("when the keychain contains an access token") {
                beforeEach {
                    keychain["access_token"] = "01234567-89ab-cdef-0123-456789abcdef"
                    keychain["token_type"] = "bearer"
                    keychain["expires_at"] = "1423578534"
                    keychain["refresh_token"] = "127386523686"
                }
                
                it("retrieves and returns the access token from the keychain") {
                    let token = store.retrieveAccessToken()
                    expect(token).toNot(beNil())
                    expect(token?.accessToken).to(equal("01234567-89ab-cdef-0123-456789abcdef"))
                    expect(token?.tokenType).to(equal("bearer"))
                    expect(token?.expiresAt).to(equal(NSDate(timeIntervalSince1970: 1423578534)))
                    expect(token?.refreshToken).to(equal("127386523686"))
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
