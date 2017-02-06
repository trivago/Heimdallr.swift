import Foundation
import Nimble
import Quick
import ReactiveSwift
import ReactiveObjC
import ReactiveHeimdallr
import Result

private let testError = NSError(domain: "MockHeimdallr", code: 123, userInfo: nil)
private let testRequest = URLRequest(url: URL(string: "http://rheinfabrik.de/members")!)

fileprivate class MockHeimdallr: Heimdallr {
    fileprivate var authorizeSuccess = true
    fileprivate var requestSuccess = true

    fileprivate override func requestAccessToken(username: String, password: String, completion: @escaping (Result<Void, NSError>) -> ()) {
        if authorizeSuccess {
            completion(Result(value: ()))
        } else {
            completion(Result(error: testError))
        }
    }

    fileprivate override func requestAccessToken(grantType: String, parameters: [String : String], completion: @escaping (Result<Void, NSError>) -> ()) {
        if authorizeSuccess {
            completion(Result(value: ()))
        } else {
            completion(Result(error: testError))
        }
    }

    fileprivate override func authenticateRequest(_ request: URLRequest, completion: @escaping (Result<URLRequest, NSError>) -> ()) {
        if requestSuccess {
            completion(Result(value: testRequest))
        } else {
            completion(Result(error: testError))
        }
    }
}

class ReactiveHeimdallrSpec: QuickSpec {
    override func spec() {
        var heimdallr: MockHeimdallr!

        beforeEach {
            heimdallr = MockHeimdallr(tokenURL: URL(string: "http://rheinfabrik.de/token")!)
        }

        describe("-requestAccessToken(username:password:)") {
            context("when the completion block sends a success result") {
                beforeEach {
                    heimdallr.authorizeSuccess = true
                }

                it("sends Void") {
                    waitUntil { done in
                        let producer = heimdallr.requestAccessToken(username: "foo", password: "bar")
                        producer.startWithResult { value in
                            done()
                        }
                    }
                }

                it("completes") {
                    waitUntil { done in
                        let producer = heimdallr.requestAccessToken(username: "foo", password: "bar")
                        producer.startWithCompleted {
                            done()
                        }
                    }
                }
            }

            context("when the completion block sends a failure result") {
                beforeEach {
                    heimdallr.authorizeSuccess = false
                }

                it("sends the error") {
                    waitUntil { done in
                        let producer = heimdallr.requestAccessToken(username: "foo", password: "bar")
                        producer.startWithFailed { error in
                            expect(error).to(equal(testError))
                            done()
                        }
                    }
                }
            }
        }

        describe("-requestAccessToken(grantType:parameters:)") {
            context("when the completion block sends a success result") {

                beforeEach {
                    heimdallr.authorizeSuccess = true
                }

                it("sends Void") {
                    waitUntil { done in
                        let producer = heimdallr.requestAccessToken(grantType:"foo", parameters: ["code": "bar"])
                        producer.startWithResult { value in
                            done()
                        }
                    }
                }

                it("completes") {
                    waitUntil { done in
                        let producer = heimdallr.requestAccessToken(grantType:"foo", parameters: ["code": "bar"])
                        producer.startWithCompleted {
                            done()
                        }
                    }
                }
            }

            context("when the completion block sends a failure result") {
                beforeEach {
                    heimdallr.authorizeSuccess = false
                }

                it("sends the error") {
                    waitUntil { done in
                        let producer = heimdallr.requestAccessToken(grantType:"foo", parameters: ["code": "bar"])
                        producer.startWithFailed { error in
                            expect(error).to(equal(testError))
                            done()
                        }
                    }
                }
            }
        }

        describe ("-authenticateRequest") {
            context("when the completion block sends a success result") {
                beforeEach {
                    heimdallr.requestSuccess = true
                }

                it("sends the result value") {
                    waitUntil { done in
                        let producer = heimdallr.authenticateRequest(request: URLRequest(url: URL(string: "http://www.rheinfabrik.de/foobar")!))
                        producer.startWithResult { result in
                            expect(result.value).to(equal(testRequest))
                            done()
                        }
                    }
                }

                it("completes") {
                    waitUntil { done in
                        let producer = heimdallr.authenticateRequest(request: URLRequest(url: URL(string: "http://www.rheinfabrik.de/foobar")!))
                        producer.startWithCompleted {
                            done()
                        }
                    }
                }
            }

            context("when the completion block sends a failure result") {
                beforeEach {
                    heimdallr.requestSuccess = false
                }

                it("sends the error") {
                    waitUntil { done in
                        let producer = heimdallr.authenticateRequest(request: URLRequest(url: URL(string: "http://www.rheinfabrik.de/foobar")!))
                        producer.startWithFailed { error in
                            expect(error).to(equal(testError))
                            done()
                        }
                    }
                }
            }
        }

        describe("-rac_requestAccessToken(username:password:)") {
            context("when the completion block sends a success result") {
                beforeEach {
                    heimdallr.authorizeSuccess = true
                }

                it("completes") {
                    waitUntil { done in
                        let signal = heimdallr.rac_requestAccessToken(username: "foo", password: "bar")
                        signal.subscribeCompleted {
                            done()
                        }
                    }
                }
            }

            context("when the completion block sends a failure result") {
                beforeEach {
                    heimdallr.authorizeSuccess = false
                }

                it("sends the error") {
                    waitUntil { done in
                        let signal = heimdallr.rac_requestAccessToken(username: "foo", password: "bar")
                        signal.subscribeError { error in
                            guard let error = error as? NSError else {
                                return
                            }
                            expect(error).to(equal(testError))
                            done()
                        }
                    }
                }
            }
        }

        describe("-rac_requestAccessToken(grantType:parameters:)") {
            context("when the completion block sends a success result") {
                beforeEach {
                    heimdallr.authorizeSuccess = true
                }

                it("completes") {
                    waitUntil { done in
                        let signal = heimdallr.rac_requestAccessToken(grantType:"foo", parameters:["code": "bar"])
                        signal.subscribeCompleted {
                            done()
                        }
                    }
                }

            }

            context("when the completion block sends a failure result") {
                beforeEach {
                    heimdallr.authorizeSuccess = false
                }

                it("sends the error") {
                    waitUntil { done in
                        let signal = heimdallr.rac_requestAccessToken(grantType:"foo", parameters:["code": "bar"])
                        signal.subscribeError { error in
                            guard let error = error as? NSError else {
                                return
                            }
                            expect(error).to(equal(testError))
                            done()
                        }
                    }
                }
            }
        }

        describe ("-rac_authenticateRequest") {
            context("when the completion block sends a success result") {
                beforeEach {
                    heimdallr.requestSuccess = true
                }

                it("sends the result value") {
                    waitUntil { done in
                        let signal = heimdallr.rac_authenticateRequest(request: NSURLRequest(url: URL(string: "http://www.rheinfabrik.de/foobar")!))
                        signal.subscribeNext { value in
                            expect(value as? URLRequest).to(equal(testRequest))
                            done()
                        }
                    }
                }

                it("completes") {
                    waitUntil { done in
                        let signal = heimdallr.rac_authenticateRequest(request: NSURLRequest(url: URL(string: "http://www.rheinfabrik.de/foobar")!))
                        signal.subscribeCompleted {
                            done()
                        }
                    }
                }
            }

            context("when the completion block sends a failure result") {
                beforeEach {
                    heimdallr.requestSuccess = false
                }

                it("sends the error") {
                    waitUntil { done in
                        let signal = heimdallr.rac_authenticateRequest(request: NSURLRequest(url: URL(string: "http://www.rheinfabrik.de/foobar")!))
                        signal.subscribeError { error in
                            guard let error = error as? NSError else {
                                return
                            }
                            expect(error).to(equal(testError))
                            done()
                        }
                    }
                }
            }
        }
    }
}
