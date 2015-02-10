//
//  OAuthManagerSpec.swift
//  oauth-swift
//
//  Created by Felix Jendrusch on 2/10/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Quick
import Nimble
import AeroGearHttpStub

import LlamaKit
import oauth_swift

public class MockStorage: OAuthAccessTokenStorage {
    
    public var storeAccessTokenCalled: Bool = false
    public var retrievedAccessToken: OAuthAccessToken? = nil
    
    public func storeAccessToken(accessToken: OAuthAccessToken){
        storeAccessTokenCalled = true
    }
    
    public func retrieveAccessToken() -> OAuthAccessToken? {
        return retrievedAccessToken
    }
    
}

class OAuthManagerSpec: QuickSpec {
    let location = StubResponse.Location.Bundle(NSBundle(forClass: OAuthManagerSpec.self))

    override func spec() {
        var manager: OAuthManager!
        var storage: MockStorage!

        beforeEach {
            manager = OAuthManager(tokenURL: NSURL(string: "http://example.com")!, clientID: "example")
            storage = MockStorage()
            manager.tokenStorage = storage
        }
        
        describe("-init") {
            
            context("when a token is saved in the storage") {
                
                it("loads the token from the token storage") {
                    storage.retrievedAccessToken = OAuthAccessToken(token: "foo", type: "bar", expiresAt: nil, refreshToken: nil)
                    expect(manager.hasAccessToken).to(beTrue())
                }
                
            }
            
        }
        
        describe("-authorize") {
            context("with a valid response") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ request in
                        return true
                    }, withStubResponse: { request in
                        return StubResponse(filename: "authorize-valid.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }); return
                }

                afterEach {
                    StubsManager.removeAllStubs()
                }

                it("succeeds") {
                    waitUntil { done in
                        manager.authorize("username", password: "password") { result in
                            expect(result.isSuccess).to(beTrue())
                            done()
                        }
                    }
                }

                it("sets the access token") {
                    waitUntil { done in
                        manager.authorize("username", password: "password") { result in
                            expect(storage.storeAccessTokenCalled).to(beTrue())
                            done()
                        }
                    }
                }
                
                it("stores the access token in the token storage") {
                    manager.authorize("username", password: "password") { result in }
                    expect(storage.storeAccessTokenCalled).toEventually(beTrue())
                }
                
            }

            context("with an invalid response") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ request in
                        return true
                    }, withStubResponse: { request in
                        return StubResponse(filename: "authorize-invalid.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }); return
                }

                afterEach {
                    StubsManager.removeAllStubs()
                }

                it("fails") {
                    waitUntil { done in
                        manager.authorize("username", password: "password") { result in
                            expect(result.isSuccess).to(beFalse())
                            expect(result.error?.code).to(equal(OAuthManagerErrorInvalidData))
                            done()
                        }
                    }
                }

                it("does not set the access token") {
                    waitUntil { done in
                        manager.authorize("username", password: "password") { result in
                            expect(manager.hasAccessToken).to(beFalse())
                            done()
                        }
                    }
                }
            }

            context("with an invalid response missing a token") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ request in
                        return true
                        }, withStubResponse: { request in
                            return StubResponse(filename: "authorize-invalid-token.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }); return
                }

                afterEach {
                    StubsManager.removeAllStubs()
                }

                it("fails") {
                    waitUntil { done in
                        manager.authorize("username", password: "password") { result in
                            expect(result.isSuccess).to(beFalse())
                            expect(result.error?.code).to(equal(OAuthManagerErrorInvalidData))
                            done()
                        }
                    }
                }

                it("does not set the access token") {
                    waitUntil { done in
                        manager.authorize("username", password: "password") { result in
                            expect(manager.hasAccessToken).to(beFalse())
                            done()
                        }
                    }
                }
            }

            context("with an invalid response missing a type") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ request in
                        return true
                        }, withStubResponse: { request in
                            return StubResponse(filename: "authorize-invalid-type.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }); return
                }

                afterEach {
                    StubsManager.removeAllStubs()
                }

                it("fails") {
                    waitUntil { done in
                        manager.authorize("username", password: "password") { result in
                            expect(result.isSuccess).to(beFalse())
                            expect(result.error?.code).to(equal(OAuthManagerErrorInvalidData))
                            done()
                        }
                    }
                }

                it("does not set the access token") {
                    waitUntil { done in
                        manager.authorize("username", password: "password") { result in
                            expect(manager.hasAccessToken).to(beFalse())
                            done()
                        }
                    }
                }
            }
        }
    }
}
