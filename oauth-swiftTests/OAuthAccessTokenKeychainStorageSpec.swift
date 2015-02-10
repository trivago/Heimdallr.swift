//
//  OAuthAccessTokenKeychainStorageSpec.swift
//  oauth-swift
//
//  Created by Tim Brückmann on 10.02.15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Quick
import Nimble
import KeychainAccess
import oauth_swift

class OAuthAccessTokenKeychainStoreSpec: QuickSpec {
    override func spec() {
        
        var storage: OAuthAccessTokenKeychainStorage!
        let keychain = Keychain(service: "de.rheinfabrik.oauth-manager.unit-tests")
        
        beforeEach {
            storage = OAuthAccessTokenKeychainStorage(service: "de.rheinfabrik.oauth-manager.unit-tests")
        }
        
        describe("-storeAccessToken") {
            
            let expirationDate = NSDate().dateByAddingTimeInterval(3600)
            let token = OAuthAccessToken(
                token: "01234567-89ab-cdef-0123-456789abcdef",
                type: "bearer",
                expiresAt: expirationDate,
                refreshToken: "127386523686")
            
            beforeEach {
                storage.storeAccessToken(token)
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
                    let token = storage.retrieveAccessToken()
                    expect(token).toNot(beNil())
                    expect(token?.token).to(equal("01234567-89ab-cdef-0123-456789abcdef"))
                    expect(token?.type).to(equal("bearer"))
                    expect(token?.expiresAt).to(equal(NSDate(timeIntervalSince1970: 1423578534)))
                    expect(token?.refreshToken).to(equal("127386523686"))
                }
                
                context("without an expiration date") {
                    
                    beforeEach {
                        keychain["expires_at"] = nil
                    }
                    
                    it("returns an access token without expiration date") {
                        let token = storage.retrieveAccessToken()
                        expect(token).toNot(beNil())
                        expect(token?.expiresAt).to(beNil())
                    }
                    
                }
                
                context("without a refresh token") {
                    
                    beforeEach {
                        keychain["refresh_token"] = nil
                    }
                    
                    it("returns an access token without refresh token") {
                        let token = storage.retrieveAccessToken()
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
                    let token = storage.retrieveAccessToken()
                    expect(token).to(beNil())
}
                
            }
            
        }
        
    }
}
