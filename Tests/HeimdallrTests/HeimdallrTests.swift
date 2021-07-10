import Foundation
import Heimdallr
import OHHTTPStubs
import XCTest

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

class HeimdallrTests: XCTestCase {
    let bundle = Bundle.module

    var accessTokenStore: OAuthAccessTokenMockStore!
    var accessTokenParser: OAuthAccessTokenInterceptorParser!
    var heimdallr: Heimdallr!
    let request = URLRequest(url: URL(string: "http://rheinfabrik.de")!)

    override func setUp() {
        accessTokenStore = OAuthAccessTokenMockStore()
        accessTokenParser = OAuthAccessTokenInterceptorParser()
        heimdallr = Heimdallr(tokenURL: URL(string: "http://rheinfabrik.de")!, accessTokenStore: accessTokenStore, accessTokenParser: accessTokenParser, resourceRequestAuthenticator: HeimdallResourceRequestMockAuthenticator())
    }

    override func tearDown() {
        accessTokenStore = nil
        accessTokenParser = nil
        heimdallr = nil
    }

    func testTokenIsSavedInTheStore() {
        accessTokenStore.mockedAccessToken = OAuthAccessToken(accessToken: "foo", tokenType: "bar")

        XCTAssertTrue(heimdallr.hasAccessToken)
    }

    func testCallingInvalidateAccessTokenInvalidatesTheToken() {
        accessTokenStore.storeAccessToken(OAuthAccessToken(accessToken: "foo", tokenType: "bar", expiresAt: Date(timeIntervalSinceNow: 3600)))
        heimdallr.invalidateAccessToken()

        XCTAssertEqual(accessTokenStore.retrieveAccessToken()?.expiresAt, Date(timeIntervalSince1970: 0))
    }

    func testCallingClearAccessTokenClearsTheToken() {
        accessTokenStore.storeAccessToken(OAuthAccessToken(accessToken: "foo", tokenType: "bar", expiresAt: Date(timeIntervalSinceNow: 3600)))
        heimdallr.clearAccessToken()

        XCTAssertFalse(heimdallr.hasAccessToken)
    }

    func testRequestingAccessTokenWithUserNameAndPasswordHasAValidResponse() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-valid", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected requestAccessToken to succeed")

        heimdallr.requestAccessToken(username: "username", password: "password") { (result) in
            XCTAssertNotNil(try? result.get())
            XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertTrue(self.heimdallr.hasAccessToken)
            XCTAssertTrue(self.accessTokenStore.storeAccessTokenCalled)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testRequestingAccessTokenWithUserNameAndPasswordHasAValidResponseAndFailingTokenParser() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-valid", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let parseError = NSError(domain: ParserErrorDomain, code: HeimdallrErrorInvalidData, userInfo: nil)

        accessTokenParser.intercept(withError: parseError)

        let expectation = XCTestExpectation(description: "Expected token parser to fail")

        heimdallr.requestAccessToken(username: "username", password: "password") { (result) in
            XCTAssertNil(try? result.get())
            XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertFalse(self.heimdallr.hasAccessToken)
            XCTAssertFalse(self.accessTokenStore.storeAccessTokenCalled)

            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case let .failure(error):
                XCTAssertEqual(error.domain, HeimdallrErrorDomain)
                XCTAssertEqual(error.code, HeimdallrErrorInvalidData)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testRequestingAccessTokenWithUserNameAndPasswordHasAnErrorResponse() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-error", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 400, headers: nil)
        })

        let expectation = XCTestExpectation(description: "Expected request to fail")

        heimdallr.requestAccessToken(username: "username", password: "password") { (result) in
            XCTAssertNil(try? result.get())
            XCTAssertFalse(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertFalse(self.heimdallr.hasAccessToken)
            XCTAssertFalse(self.accessTokenStore.storeAccessTokenCalled)

            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case let .failure(error):
                XCTAssertEqual(error.domain, OAuthErrorDomain)
                XCTAssertEqual(error.code, OAuthErrorInvalidClient)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testRequestingAccessTokenWithUserNameAndPasswordHasAnInvalidResponse() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected request to be invalid")

        heimdallr.requestAccessToken(username: "username", password: "password") { (result) in
            XCTAssertNil(try? result.get())
            XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertFalse(self.heimdallr.hasAccessToken)
            XCTAssertFalse(self.accessTokenStore.storeAccessTokenCalled)

            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case let .failure(error):
                XCTAssertEqual(error.domain, HeimdallrErrorDomain)
                XCTAssertEqual(error.code, HeimdallrErrorInvalidData)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testRequestingAccessTokenWithUserNameAndPasswordHasAnInvalidResponseWithMissingToken() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid-token", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected request to be invalid with missing token")

        heimdallr.requestAccessToken(username: "username", password: "password") { (result) in
            XCTAssertNil(try? result.get())
            XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertFalse(self.heimdallr.hasAccessToken)
            XCTAssertFalse(self.accessTokenStore.storeAccessTokenCalled)

            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case let .failure(error):
                XCTAssertEqual(error.domain, HeimdallrErrorDomain)
                XCTAssertEqual(error.code, HeimdallrErrorInvalidData)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testRequestingAccessTokenWithUserNameAndPasswordHasAnInvalidResponseWithMissingType() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid-type", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected request to be invalid with missing type")

        heimdallr.requestAccessToken(username: "username", password: "password") { (result) in
            XCTAssertNil(try? result.get())
            XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertFalse(self.heimdallr.hasAccessToken)
            XCTAssertFalse(self.accessTokenStore.storeAccessTokenCalled)

            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case let .failure(error):
                XCTAssertEqual(error.domain, HeimdallrErrorDomain)
                XCTAssertEqual(error.code, HeimdallrErrorInvalidData)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testRequestingAccessTokenWithGrantTypeHasAValidResponse() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-valid", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected requestAccessToken to succeed")

        heimdallr.requestAccessToken(grantType: "https://accounts.example.com/oauth/v2/foo/bar", parameters: ["provider": "fb", "code": "tops3cret"]) { (result) in
            XCTAssertNotNil(try? result.get())
            XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertTrue(self.heimdallr.hasAccessToken)
            XCTAssertTrue(self.accessTokenStore.storeAccessTokenCalled)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testRequestingAccessTokenWithGrantTypeHasAnErrorResponse() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-error", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 400, headers: nil)
        })

        let expectation = XCTestExpectation(description: "Expected requestAccessToken to succeed")

        heimdallr.requestAccessToken(grantType: "https://accounts.example.com/oauth/v2/foo/bar", parameters: ["provider": "fb", "code": "tops3cret"]) { (result) in
            XCTAssertNil(try? result.get())
            XCTAssertFalse(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertFalse(self.heimdallr.hasAccessToken)
            XCTAssertFalse(self.accessTokenStore.storeAccessTokenCalled)

            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case let .failure(error):
                XCTAssertEqual(error.domain, OAuthErrorDomain)
                XCTAssertEqual(error.code, OAuthErrorInvalidClient)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testRequestingAccessTokenWithGrantTypeHasAnInvalidResponse() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected requestAccessToken to have invalid response")

        heimdallr.requestAccessToken(grantType: "https://accounts.example.com/oauth/v2/foo/bar", parameters: ["provider": "fb", "code": "tops3cret"]) { (result) in
            XCTAssertNil(try? result.get())
            XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertFalse(self.heimdallr.hasAccessToken)
            XCTAssertFalse(self.accessTokenStore.storeAccessTokenCalled)

            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case let .failure(error):
                XCTAssertEqual(error.domain, HeimdallrErrorDomain)
                XCTAssertEqual(error.code, HeimdallrErrorInvalidData)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testRequestingAccessTokenWithGrantTypeHasAnInvalidResponseMissingToken() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid-token", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected requestAccessToken to have invalid response with missing token")

        heimdallr.requestAccessToken(grantType: "https://accounts.example.com/oauth/v2/foo/bar", parameters: ["provider": "fb", "code": "tops3cret"]) { (result) in
            XCTAssertNil(try? result.get())
            XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertFalse(self.heimdallr.hasAccessToken)
            XCTAssertFalse(self.accessTokenStore.storeAccessTokenCalled)

            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case let .failure(error):
                XCTAssertEqual(error.domain, HeimdallrErrorDomain)
                XCTAssertEqual(error.code, HeimdallrErrorInvalidData)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testRequestingAccessTokenWithGrantTypeHasAnInvalidResponseMissingType() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-invalid-type", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected requestAccessToken to have invalid response with missing type")

        heimdallr.requestAccessToken(grantType: "https://accounts.example.com/oauth/v2/foo/bar", parameters: ["provider": "fb", "code": "tops3cret"]) { (result) in
            XCTAssertNil(try? result.get())
            XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
            XCTAssertFalse(self.heimdallr.hasAccessToken)
            XCTAssertFalse(self.accessTokenStore.storeAccessTokenCalled)

            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case let .failure(error):
                XCTAssertEqual(error.domain, HeimdallrErrorDomain)
                XCTAssertEqual(error.code, HeimdallrErrorInvalidData)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testAuthenticateRequestWhenNotAuthorized() {
        let expectation = XCTestExpectation(description: "Expected authenticateRequest to fail with not authorized")

        heimdallr.authenticateRequest(request) { (result) in
            XCTAssertNil(try? result.get())

            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case let .failure(error):
                XCTAssertEqual(error.domain, HeimdallrErrorDomain)
                XCTAssertEqual(error.code, HeimdallrErrorNotAuthorized)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    func testAuthenticateRequestWhenAuthorized() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "request-valid", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected authenticateRequest to fail with not authorized")

        heimdallr.requestAccessToken(username: "username", password: "password") { _ in
            self.heimdallr.authenticateRequest(self.request) { (result) in
                let success = try? result.get()
                XCTAssertNotNil(success)
                XCTAssertEqual(success?.value(forHTTPHeaderField: "MockAuthorized"), "totally")

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testAuthenticateRequestWhenAuthorizedWithExpiredAccessTokenAndNoRefreshToken() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (request.url!.absoluteString == "http://rheinfabrik.de")
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "request-invalid-norefresh", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected authenticateRequest to fail with expired access token and no refresh token")

        heimdallr.requestAccessToken(username: "username", password: "password") { _ in
            self.heimdallr.authenticateRequest(self.request) { (result) in
                XCTAssertNil(try? result.get())

                switch result {
                case .success:
                    XCTFail("Expected request to fail")
                case let .failure(error):
                    XCTAssertEqual(error.domain, HeimdallrErrorDomain)
                    XCTAssertEqual(error.code, HeimdallrErrorNotAuthorized)
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testAuthenticateRequestWhenAuthorizedWithExpiredAccessTokenAndAValidRefreshToken() {
        HTTPStubs.stubRequests(passingTest: { request in
            return (
                request.url!.absoluteString == "http://rheinfabrik.de"
                    && self.heimdallr.hasAccessToken == false
            )
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "request-invalid", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected authenticateRequest to fail with expired access token and a valid refresh token")

        heimdallr.requestAccessToken(username: "username", password: "password") { _ in
            HTTPStubs.stubRequests(passingTest: { request in
                return (request.url!.absoluteString == "http://rheinfabrik.de")
            }, withStubResponse: { request in
                let data = try! Data(contentsOf: self.bundle.url(forResource: "request-invalid", withExtension: "json")!)
                return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
            })

            self.heimdallr.authenticateRequest(self.request) { (result) in
                let success = try? result.get()
                XCTAssertNotNil(success)
                XCTAssertEqual(success?.value(forHTTPHeaderField: "MockAuthorized"), "totally")
                XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
                XCTAssertEqual(self.accessTokenParser.timesCalled, 2)

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testAuthenticateRequestWhenAuthorizedAndRefreshingAccessTokenFails() {
        let expectation = XCTestExpectation(description: "Expected authenticateRequest to fail refreshing access token")

        HTTPStubs.stubRequests(passingTest: { request in
            return (
                request.url!.absoluteString == "http://rheinfabrik.de"
                    && self.heimdallr.hasAccessToken == false
            )
        }, withStubResponse: { request in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "request-invalid", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        heimdallr.requestAccessToken(username: "username", password: "password") { _ in
            HTTPStubs.stubRequests(passingTest: { request in
                return (request.url!.absoluteString == "http://rheinfabrik.de")
            }, withStubResponse: { request in
                let data = try! Data(contentsOf: self.bundle.url(forResource: "authorize-error", withExtension: "json")!)
                return HTTPStubsResponse(data: data, statusCode: 400, headers: [ "Content-Type": "application/json" ])
            })

            self.heimdallr.authenticateRequest(self.request) { (result) in
                XCTAssertNil(try? result.get())
                XCTAssertFalse(self.heimdallr.hasAccessToken)
                XCTAssertTrue(self.accessTokenParser.parseAccessTokenCalled)
                XCTAssertEqual(self.accessTokenParser.timesCalled, 1)

                switch result {
                case .success:
                    XCTFail("Expected request to fail")
                case let .failure(error):
                    XCTAssertEqual(error.domain, OAuthErrorDomain)
                    XCTAssertEqual(error.code, OAuthErrorInvalidClient)
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }

    func testAuthenticatingMultipleRequestsWithAnExpiredAccessToken() {
        var firstAuthenticationRequestDone = false
        var madeNetworkRequestAfterFirstAuthenticationRequestDone = false

        HTTPStubs.stubRequests(passingTest: { _ in
            if firstAuthenticationRequestDone {
                madeNetworkRequestAfterFirstAuthenticationRequestDone = true
            }
            return true
        }, withStubResponse: { _ in
            let data = try! Data(contentsOf: self.bundle.url(forResource: "request-valid", withExtension: "json")!)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: [ "Content-Type": "application/json" ])
        })

        let expectation = XCTestExpectation(description: "Expected multiple requests to validate")

        var firstFinished = false
        heimdallr.authenticateRequest(request) { _ in
            firstAuthenticationRequestDone = true
            firstFinished ? expectation.fulfill() : (firstFinished = true)
        }
        heimdallr.authenticateRequest(request) { _ in
            firstFinished ? expectation.fulfill() : (firstFinished = true)
        }

        XCTAssertFalse(madeNetworkRequestAfterFirstAuthenticationRequestDone)

        wait(for: [expectation], timeout: 2)

        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
    }
}
