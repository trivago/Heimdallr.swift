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

class OAuthManagerSpec: QuickSpec {
    let location = StubResponse.Location.Bundle(NSBundle(forClass: OAuthManagerSpec.self))

    override func spec() {
        var manager: OAuthManager!

        beforeEach {
            manager = OAuthManager(tokenURL: NSURL(string: "http://rheinfabrik.de")!, clientID: "spec")
        }

        describe("-authorize") {
            var result: Result<Void, NSError>?

            afterEach {
                result = nil
            }

            context("with a valid response") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ _ in true }) { request in
                        return StubResponse(filename: "authorize-valid.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }

                    waitUntil { done in
                        manager.authorize("username", password: "password") { result = $0; done() }
                    }
                }

                afterEach {
                    StubsManager.removeAllStubs()
                }

                it("succeeds") {
                    expect(result?.isSuccess).to(beTrue())
                }

                it("sets the access token") {
                    expect(manager.hasAccessToken).to(beTrue())
                }
            }

            context("with an invalid response") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ _ in true }) { request in
                        return StubResponse(filename: "authorize-invalid.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }

                    waitUntil { done in
                        manager.authorize("username", password: "password") { result = $0; done() }
                    }
                }

                afterEach {
                    StubsManager.removeAllStubs()
                }

                it("fails") {
                    expect(result?.isSuccess).to(beFalse())
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(OAuthManagerErrorInvalidData))
                }

                it("does not set the access token") {
                    expect(manager.hasAccessToken).to(beFalse())
                }
            }

            context("with an invalid response missing a token") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ _ in true }) { request in
                        return StubResponse(filename: "authorize-invalid-token.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }

                    waitUntil { done in
                        manager.authorize("username", password: "password") { result = $0; done() }
                    }
                }

                afterEach {
                    StubsManager.removeAllStubs()
                }

                it("fails") {
                    expect(result?.isSuccess).to(beFalse())
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(OAuthManagerErrorInvalidData))
                }

                it("does not set the access token") {
                    expect(manager.hasAccessToken).to(beFalse())
                }
            }

            context("with an invalid response missing a type") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ _ in true }) { request in
                        return StubResponse(filename: "authorize-invalid-type.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }

                    waitUntil { done in
                        manager.authorize("username", password: "password") { result = $0; done() }
                    }
                }

                afterEach {
                    StubsManager.removeAllStubs()
                }

                it("fails") {
                    expect(result?.isSuccess).to(beFalse())
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(OAuthManagerErrorInvalidData))
                }

                it("does not set the access token") {
                    expect(manager.hasAccessToken).to(beFalse())
                }
            }
        }
    }
}
