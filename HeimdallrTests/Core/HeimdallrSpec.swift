import Heimdallr
import Nimble
import OHHTTPStubs
import Quick
import Result

class OAuthAccessTokenMockStore: OAuthAccessTokenStore {
    var storeAccessTokenCalled: Bool = false

    var mockedAccessToken: OAuthAccessToken? = nil
    var storedAccessToken: OAuthAccessToken? = nil

    @objc func storeAccessToken(_ accessToken: OAuthAccessToken?) {
        storeAccessTokenCalled = true

        storedAccessToken = accessToken
    }

    @objc func retrieveAccessToken() -> OAuthAccessToken? {
        return mockedAccessToken ?? storedAccessToken
    }
}

let ParserErrorDomain = "ParserErrorDomain"

class OAuthAccessTokenInterceptorParser: OAuthAccessTokenParser {
    
    let defaultParser = OAuthAccessTokenDefaultParser()
    
    var timesCalled = 0
    
    var shouldIntercept: Bool = false
    var interceptToken: OAuthAccessToken?
    var interceptError: NSError?
    
    func intercept(withToken token: OAuthAccessToken) {
        shouldIntercept = true
        interceptToken = token
    }
    
    func intercept(withError error: NSError) {
        shouldIntercept = true
        interceptError = error
    }
    
    @objc func parse(data: Data) throws -> OAuthAccessToken {
        
        timesCalled += 1
        
        if self.shouldIntercept {
            if let accessToken = self.interceptToken {
                return accessToken
            } else if let error = self.interceptError {
                throw error
            } else {
                fatalError("Missing intercept token or error")
            }
        } else {
            return try defaultParser.parse(data: data)
        }
    }
    
    var parseAccessTokenCalled: Bool {
        return timesCalled > 0
    }
}

class HeimdallResourceRequestMockAuthenticator: HeimdallResourceRequestAuthenticator {
    @objc func authenticateResourceRequest(_ request: URLRequest, accessToken: OAuthAccessToken) -> URLRequest {
        var mutableRequest = request
        mutableRequest.addValue("totally", forHTTPHeaderField: "MockAuthorized")
        return mutableRequest
    }
}

class HeimdallrSpec: QuickSpec {
    let bundle = Bundle(for: HeimdallrSpec.self)

    override func spec() {
        var accessTokenStore: OAuthAccessTokenMockStore!
        var accessTokenParser: OAuthAccessTokenInterceptorParser!
        var heimdallr: Heimdallr!

        beforeEach {
            accessTokenStore = OAuthAccessTokenMockStore()
            accessTokenParser = OAuthAccessTokenInterceptorParser()
            heimdallr = Heimdallr(tokenURL: URL(string: "http://rheinfabrik.de")!, accessTokenStore: accessTokenStore, accessTokenParser: accessTokenParser, resourceRequestAuthenticator: HeimdallResourceRequestMockAuthenticator())
        }

        describe("-init") {
            context("when a token is saved in the store") {
                it("loads the token from the token store") {
                    accessTokenStore.mockedAccessToken = OAuthAccessToken(accessToken: "foo", tokenType: "bar")
                    expect(heimdallr.hasAccessToken).to(beTrue())
                }
            }
        }

        describe("-invalidateAccessToken") {
            beforeEach {
                accessTokenStore.storeAccessToken(OAuthAccessToken(accessToken: "foo", tokenType: "bar", expiresAt: Date(timeIntervalSinceNow: 3600)))
            }

            it("invalidates the currently stored access token") {
                heimdallr.invalidateAccessToken()

                expect(accessTokenStore.retrieveAccessToken()?.expiresAt).to(equal(Date(timeIntervalSince1970: 0)))
            }
        }

        describe("-clearAccessToken") {
            beforeEach {
                accessTokenStore.storeAccessToken(OAuthAccessToken(accessToken: "foo", tokenType: "bar", expiresAt: Date(timeIntervalSinceNow: 3600)))
            }

            it("clears the currently stored access token") {
                heimdallr.clearAccessToken()

                expect(heimdallr.hasAccessToken).to(beFalse())
            }
        }

        describe("-requestAccessToken(username:password:completion:)") {
            var result: Result<Void, NSError>?

            afterEach {
                result = nil
            }

            context("with a valid response") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-valid", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(username: "username", password: "password") { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("succeeds") {
                    expect(result?.value).toNot(beNil())
                }

                it("attempts to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beTrue())
                }

                it("sets the access token") {
                    expect(heimdallr.hasAccessToken).to(beTrue())
                }

                it("stores the access token in the token store") {
                    expect(accessTokenStore.storeAccessTokenCalled).to(beTrue())
                }
            }
            
            context("with a valid response and a failing token parser") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                        }, withStubResponse: { request in
                            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-valid", withExtension: "json")!)
                            return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })
                    
                    let parseError = NSError(domain: ParserErrorDomain, code: HeimdallrErrorInvalidData, userInfo: nil)
                    
                    accessTokenParser.intercept(withError: parseError)
                    
                    waitUntil { done in
                        heimdallr.requestAccessToken(username: "username", password: "password") { result = $0; done() }
                    }
                }
                
                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }
                
                it("fails") {
                    expect(result?.value).to(beNil())
                }
                
                it("attempts to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beTrue())
                }
                
                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(HeimdallrErrorDomain))
                }
                
                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(HeimdallrErrorInvalidData))
                }
                
                it("does not set the access token") {
                    expect(heimdallr.hasAccessToken).to(beFalse())
                }
                
            }

            context("with an error response") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-error", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 400, headers: nil)
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(username: "username", password: "password") { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("fails") {
                    expect(result?.value).to(beNil())
                }
                
                it("does not attempt to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beFalse())
                }

                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(OAuthErrorDomain))
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(OAuthErrorInvalidClient))
                }

                it("does not set the access token") {
                    expect(heimdallr.hasAccessToken).to(beFalse())
                }
            }

            context("with an invalid response") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(username: "username", password: "password") { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("fails") {
                    expect(result?.value).to(beNil())
                }
                
                it("attempts to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beTrue())
                }

                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(HeimdallrErrorDomain))
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(HeimdallrErrorInvalidData))
                }

                it("does not set the access token") {
                    expect(heimdallr.hasAccessToken).to(beFalse())
                }
            }

            context("with an invalid response missing a token") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid-token", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(username: "username", password: "password") { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("fails") {
                    expect(result?.value).to(beNil())
                }
                
                it("attempts to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beTrue())
                }

                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(HeimdallrErrorDomain))
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(HeimdallrErrorInvalidData))
                }

                it("does not set the access token") {
                    expect(heimdallr.hasAccessToken).to(beFalse())
                }

            }

            context("with an invalid response missing a type") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid-type", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(username: "username", password: "password") { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("fails") {
                    expect(result?.value).to(beNil())
                }
                
                it("attempts to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beTrue())
                }

                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(HeimdallrErrorDomain))
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(HeimdallrErrorInvalidData))
                }

                it("does not set the access token") {
                    expect(heimdallr.hasAccessToken).to(beFalse())
                }
            }
        }

        describe("-requestAccessToken(grantType:parameters:completion:)") {
            var result: Result<Void, NSError>?

            afterEach {
                result = nil
            }

            context("with a valid response") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-valid", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(grantType: "https://accounts.example.com/oauth/v2/foo/bar", parameters: ["provider": "fb", "code": "tops3cret"]) { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("succeeds") {
                    expect(result?.value).toNot(beNil())
                }
                
                it("attempts to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beTrue())
                }

                it("sets the access token") {
                    expect(heimdallr.hasAccessToken).to(beTrue())
                }

                it("stores the access token in the token store") {
                    expect(accessTokenStore.storeAccessTokenCalled).to(beTrue())
                }
            }

            context("with an error response") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-error", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 400, headers: nil)
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(grantType: "https://accounts.example.com/oauth/v2/foo/bar", parameters: ["provider": "fb", "code": "tops3cret"]) { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("fails") {
                    expect(result?.value).to(beNil())
                }

                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(OAuthErrorDomain))
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(OAuthErrorInvalidClient))
                }

                it("does not set the access token") {
                    expect(heimdallr.hasAccessToken).to(beFalse())
                }
            }

            context("with an invalid response") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(grantType: "https://accounts.example.com/oauth/v2/foo/bar", parameters: ["provider": "fb", "code": "tops3cret"]) { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("fails") {
                    expect(result?.value).to(beNil())
                }
                
                it("attempts to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beTrue())
                }

                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(HeimdallrErrorDomain))
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(HeimdallrErrorInvalidData))
                }

                it("does not set the access token") {
                    expect(heimdallr.hasAccessToken).to(beFalse())
                }
            }

            context("with an invalid response missing a token") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid-token", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(grantType: "https://accounts.example.com/oauth/v2/foo/bar", parameters: ["provider": "fb", "code": "tops3cret"]) { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("fails") {
                    expect(result?.value).to(beNil())
                }
                
                it("attempts to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beTrue())
                }

                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(HeimdallrErrorDomain))
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(HeimdallrErrorInvalidData))
                }

                it("does not set the access token") {
                    expect(heimdallr.hasAccessToken).to(beFalse())
                }
            }

            context("with an invalid response missing a type") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid-type", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(grantType: "https://accounts.example.com/oauth/v2/foo/bar", parameters: ["provider": "fb", "code": "tops3cret"]) { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("fails") {
                    expect(result?.value).to(beNil())
                }
                
                it("attempts to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beTrue())
                }

                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(HeimdallrErrorDomain))
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(HeimdallrErrorInvalidData))
                }

                it("does not set the access token") {
                    expect(heimdallr.hasAccessToken).to(beFalse())
                }
            }
        }

        describe("-authenticateRequest") {
            let request = URLRequest(url: URL(string: "http://rheinfabrik.de")!)
            var result: Result<URLRequest, NSError>?

            afterEach {
                result = nil
            }

            context("when not authorized") {
                beforeEach {
                    waitUntil { done in
                        heimdallr.authenticateRequest(request) { result = $0; done() }
                    }
                }

                it("fails") {
                    expect(result?.value).to(beNil())
                }

                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(HeimdallrErrorDomain))
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(HeimdallrErrorNotAuthorized))
                }
            }

            context("when authorized with a still valid access token") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "request-valid", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(username: "username", password: "password") { _ in done() }
                    }

                    waitUntil { done in
                        heimdallr.authenticateRequest(request) { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("succeeds") {
                    expect(result?.value).toNot(beNil())
                }

                it("authenticates the request using the resource request authenticator") {
                    expect(result?.value?.value(forHTTPHeaderField: "MockAuthorized")).to(equal("totally"))
                }

            }

            context("when authorized with an expired access token and no refresh token") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (request.url!.absoluteString == "http://rheinfabrik.de")
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "request-invalid-norefresh", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(username: "username", password: "password") { _ in done() }
                    }

                    waitUntil { done in
                        heimdallr.authenticateRequest(request) { result = $0; done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }

                it("fails") {
                    expect(result?.value).to(beNil())
                }

                it("fails with the correct error domain") {
                    expect(result?.error?.domain).to(equal(HeimdallrErrorDomain))
                }

                it("fails with the correct error code") {
                    expect(result?.error?.code).to(equal(HeimdallrErrorNotAuthorized))
                }

            }

            context("when authorized with an expired access token and a valid refresh token") {
                beforeEach {
                    OHHTTPStubs.stubRequests(passingTest: { request in
                        return (
                            request.url!.absoluteString == "http://rheinfabrik.de"
                            && heimdallr.hasAccessToken == false
                            )
                    }, withStubResponse: { request in
                        let data = try! Data(contentsOf: self.bundle.url(forResource: "request-invalid", withExtension: "json")!)
                        return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                    })

                    waitUntil { done in
                        heimdallr.requestAccessToken(username: "username", password: "password") { _ in done() }
                    }
                }

                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }
                
                it("attempts to parse the access token") {
                    expect(accessTokenParser.parseAccessTokenCalled).to(beTrue())
                }

                context("when refreshing the access token succeeds") {
                    beforeEach {
                        OHHTTPStubs.stubRequests(passingTest: { request in
                            return (request.url!.absoluteString == "http://rheinfabrik.de")
                        }, withStubResponse: { request in
                            let data = try! Data(contentsOf: self.bundle.url(forResource: "request-invalid", withExtension: "json")!)
                            return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                        })

                        waitUntil { done in
                            heimdallr.authenticateRequest(request) { result = $0; done() }
                        }
                    }

                    it("succeeds") {
                        expect(result?.value).toNot(beNil())
                    }
                    
                    it("attempts to parse the fresh token") {
                        expect(accessTokenParser.timesCalled).to(equal(2))
                    }

                    it("authenticates the request using the resource request authenticator") {
                        expect(result?.value?.value(forHTTPHeaderField: "MockAuthorized")).to(equal("totally"))
                    }
                }

                context("when refreshing the access token fails") {
                    beforeEach {
                        OHHTTPStubs.stubRequests(passingTest: { request in
                            return (request.url!.absoluteString == "http://rheinfabrik.de")
                        }, withStubResponse: { request in
                            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-error", withExtension: "json")!)
                            return OHHTTPStubsResponse(data: data, statusCode: 400, headers: [ "Content-Type": "application/json" ])
                        })
                        
                        waitUntil { done in
                            heimdallr.authenticateRequest(request) { result = $0; done() }
                        }
                    }

                    it("clears the access token") {
                        expect(heimdallr.hasAccessToken).to(beFalse())
                    }

                    it("fails") {
                        expect(result?.value).to(beNil())
                    }
                    
                    it("does not attempt to parse the fresh token") {
                        expect(accessTokenParser.timesCalled).to(equal(1))
                    }

                    it("fails with the correct error domain") {
                        expect(result?.error?.domain).to(equal(OAuthErrorDomain))
                    }

                    it("fails with the correct error code") {
                        expect(result?.error?.code).to(equal(OAuthErrorInvalidClient))
                    }
                }

                context("when authenticating multiple requests at the same time with an expired access token") {
                    it("only the first one triggers a token refresh") {
                        var firstAuthenticateRequestDone = false
                        var madeNetworkRequestAfterFirstAuthenticateRequestDone = false
                        OHHTTPStubs.stubRequests(passingTest: { _ in
                                if firstAuthenticateRequestDone {
                                    madeNetworkRequestAfterFirstAuthenticateRequestDone = true
                                }
                                return true
                            }, withStubResponse: { _ in
                                let data = try! Data(contentsOf: self.bundle.url(forResource: "request-valid", withExtension: "json")!)
                                return OHHTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
                        })

                        waitUntil { done in
                            var firstFinished = false
                            heimdallr.authenticateRequest(request) { _ in
                                firstAuthenticateRequestDone = true
                                firstFinished ? done() : (firstFinished = true)
                            }
                            heimdallr.authenticateRequest(request) { _ in
                                firstFinished ? done() : (firstFinished = true)
                            }
                        }

                        expect(madeNetworkRequestAfterFirstAuthenticateRequestDone).to(beFalse())
                    }
                }
            }
        }
    }
}
