import Foundation
import Nimble
import Quick
import ReactiveCocoa
import ReactiveHeimdallr
import Result

private let testError = NSError(domain: "MockHeimdallr", code: 123, userInfo: nil)
private let testRequest = NSURLRequest(URL: NSURL(string: "http://rheinfabrik.de/members")!)

private class MockHeimdallr: Heimdallr {
    private var authorizeSuccess = true
    private var requestSuccess = true

    private override func requestAccessToken(username username: String, password: String, completion: Result<Void, NSError> -> ()) {
        if authorizeSuccess {
            completion(Result(value: ()))
        } else {
            completion(Result(error: testError))
        }
    }

    private override func requestAccessToken(grantType grantType: String, parameters: [String: String], completion: Result<Void, NSError> -> ()) {
        if authorizeSuccess {
            completion(Result(value: ()))
        } else {
            completion(Result(error: testError))
        }
    }

    private override func authenticateRequest(request: NSURLRequest, completion: Result<NSURLRequest, NSError> -> ()) {
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
            heimdallr = MockHeimdallr(tokenURL: NSURL(string: "http://rheinfabrik.de/token")!)
        }

        describe("-requestAccessToken(username:password:)") {
            context("when the completion block sends a success result") {
                beforeEach {
                    heimdallr.authorizeSuccess = true
                }

                it("sends Void") {
                    waitUntil { done in
                        let producer = heimdallr.requestAccessToken(username: "foo", password: "bar")
                        producer.startWithNext { value in
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
                        producer.startWithNext { value in
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
                        let producer = heimdallr.authenticateRequest(NSURLRequest(URL: NSURL(string: "http://www.rheinfabrik.de/foobar")!))
                        producer.startWithNext { value in
                            expect(value).to(equal(testRequest))
                            done()
                        }
                    }
                }

                it("completes") {
                    waitUntil { done in
                        let producer = heimdallr.authenticateRequest(NSURLRequest(URL: NSURL(string: "http://www.rheinfabrik.de/foobar")!))
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
                        let producer = heimdallr.authenticateRequest(NSURLRequest(URL: NSURL(string: "http://www.rheinfabrik.de/foobar")!))
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

                it("sends a RACUnit") {
                    waitUntil { done in
                        let signal = heimdallr.rac_requestAccessToken(username: "foo", password: "bar")
                        signal.subscribeNext { value in
                            expect(value is RACUnit).to(beTrue())
                            done()
                        }
                    }
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

                it("sends a RACUnit") {
                    waitUntil { done in
                        let signal = heimdallr.rac_requestAccessToken(grantType:"foo", parameters:["code": "bar"])
                        signal.subscribeNext { value in
                            expect(value is RACUnit).to(beTrue())
                            done()
                        }
                    }
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
                        let signal = heimdallr.rac_authenticateRequest(NSURLRequest(URL: NSURL(string: "http://www.rheinfabrik.de/foobar")!))
                        signal.subscribeNext { value in
                            expect(value as? NSURLRequest).to(equal(testRequest))
                            done()
                        }
                    }
                }

                it("completes") {
                    waitUntil { done in
                        let signal = heimdallr.rac_authenticateRequest(NSURLRequest(URL: NSURL(string: "http://www.rheinfabrik.de/foobar")!))
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
                        let signal = heimdallr.rac_authenticateRequest(NSURLRequest(URL: NSURL(string: "http://www.rheinfabrik.de/foobar")!))
                        signal.subscribeError { error in
                            expect(error).to(equal(testError))
                            done()
                        }
                    }
                }
            }
        }
    }
}
