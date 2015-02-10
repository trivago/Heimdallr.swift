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

        describe("-requestByAddingAuthorizationToRequest") {
            var request = NSURLRequest(URL: NSURL(string: "http://rheinfabrik.de")!)
            var result: Result<NSURLRequest, NSError>?

            afterEach {
                result = nil
            }

            context("when not authorized") {
                beforeEach {
                    waitUntil { done in
                        manager.requestByAddingAuthorizationToRequest(request) { result = $0; done() }
                    }
                }

                it("fails") {
                    expect(result?.isSuccess).to(beFalse())
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(OAuthManagerErrorNotAuthorized))
                }
            }

            context("when authorized with a still valid access token") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ _ in true }) { request in
                        return StubResponse(filename: "request-valid.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }

                    waitUntil { done in
                        manager.authorize("username", password: "password") { _ in done() }
                    }

                    waitUntil { done in
                        manager.requestByAddingAuthorizationToRequest(request) { result = $0; done() }
                    }
                }

                it("succeed") {
                    expect(result?.isSuccess).to(beTrue())
                }

                it("add the correct authorization header to the request") {
                    expect(result?.value?.valueForHTTPHeaderField("Authorization")).to(equal("bearer MTQzM2U3YTI3YmQyOWQ5YzQ0NjY4YTZkYjM0MjczYmZhNWI1M2YxM2Y1MjgwYTg3NDk3ZDc4ZGUzM2YxZmJjZQ"))
                }
            }

            context("when authorized with an expired access token and no refresh token") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ _ in true }) { request in
                        return StubResponse(filename: "request-invalid-norefresh.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }

                    waitUntil { done in
                        manager.authorize("username", password: "password") { _ in done() }
                    }

                    waitUntil { done in
                        manager.requestByAddingAuthorizationToRequest(request) { result = $0; done() }
                    }
                }

                it("fails") {
                    expect(result?.isSuccess).to(beFalse())
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(OAuthManagerErrorNotAuthorized))
                }
            }

            context("when authorized with an expired access token and a valid refresh token") {
                beforeEach {
                    StubsManager.stubRequestsPassingTest({ _ in !manager.hasAccessToken }) { request in
                        return StubResponse(filename: "request-invalid.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }

                    waitUntil { done in
                        manager.authorize("username", password: "password") { _ in done() }
                    }

                    StubsManager.stubRequestsPassingTest({ _ in true }) { request in
                        return StubResponse(filename: "request-valid.json", location: self.location, statusCode: 200, headers: ["Content-Type" : "application/json"])
                    }

                    waitUntil { done in
                        manager.requestByAddingAuthorizationToRequest(request) { result = $0; done() }
                    }
                }

                it("succeed") {
                    expect(result?.isSuccess).to(beTrue())
                }

                it("add the correct authorization header to the request") {
                    expect(result?.value?.valueForHTTPHeaderField("Authorization")).to(equal("bearer MTQzM2U3YTI3YmQyOWQ5YzQ0NjY4YTZkYjM0MjczYmZhNWI1M2YxM2Y1MjgwYTg3NDk3ZDc4ZGUzM2YxZmJjZQ"))
                }
            }
        }
    }
}
