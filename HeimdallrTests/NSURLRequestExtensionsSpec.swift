import Heimdallr
import Nimble
import Quick

class HTTPAuthenticationSpec: QuickSpec {
    override func spec() {
        describe("<Equatable> ==") {
            context("BasicAuthentication") {
                it("returns true if usernames and passwords match") {
                    let lhs: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")
                    let rhs: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")

                    expect(lhs == rhs).to(beTrue())
                }

                it("returns false if usernames do not match") {
                    let lhs: HTTPAuthentication = .BasicAuthentication(username: "usernamea", password: "password")
                    let rhs: HTTPAuthentication = .BasicAuthentication(username: "usernameb", password: "password")

                    expect(lhs == rhs).to(beFalse())
                }

                it("returns false if password do not match") {
                    let lhs: HTTPAuthentication = .BasicAuthentication(username: "username", password: "passworda")
                    let rhs: HTTPAuthentication = .BasicAuthentication(username: "username", password: "passwordb")

                    expect(lhs == rhs).to(beFalse())
                }
            }

            context("Unknown") {
                it("returns true if accessTokens and tokenTypes match") {
                    let lhs: HTTPAuthentication = .AccessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType"))
                    let rhs: HTTPAuthentication = .AccessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType"))

                    expect(lhs == rhs).to(beTrue())
                }

                it("returns false if accessTokens do not match") {
                    let lhs: HTTPAuthentication = .AccessTokenAuthentication(OAuthAccessToken(accessToken: "accessTokena", tokenType: "tokenType"))
                    let rhs: HTTPAuthentication = .AccessTokenAuthentication(OAuthAccessToken(accessToken: "accessTokenb", tokenType: "tokenType"))

                    expect(lhs == rhs).to(beFalse())
                }

                it("returns false if tokenTypes do not match") {
                    let lhs: HTTPAuthentication = .AccessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenTypeb"))
                    let rhs: HTTPAuthentication = .AccessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenTypea"))

                    expect(lhs == rhs).to(beFalse())
                }
            }

            context("Mixed") {
                it("returns false if authentication methods do not match") {
                    let lhs: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")
                    let rhs: HTTPAuthentication = .AccessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType"))

                    expect(lhs == rhs).to(beFalse())
                }
            }
        }
    }
}

class NSURLRequestExtensionsSpec: QuickSpec {
    override func spec() {
        var request: NSMutableURLRequest!

        beforeEach {
            request = NSMutableURLRequest()
        }

        describe(".HTTPAuthorization") {
            it("returns nil if the Authorization header is not set") {
                expect(request.HTTPAuthorization).to(beNil())
            }

            it("returns the Authorization header as String if set") {
                request.setValue("Basic dXNlcm5hbWU6cGFzc3dvcmQ=", forHTTPHeaderField: "Authorization")

                expect(request.HTTPAuthorization).to(equal("Basic dXNlcm5hbWU6cGFzc3dvcmQ="))
            }
        }
    }
}

class NSMutableURLRequestExtensionsSpec: QuickSpec {
    override func spec() {
        var request: NSMutableURLRequest!

        beforeEach {
            request = NSMutableURLRequest()
        }

        describe("-setHTTPAuthorization") {
            context("when given nil") {
                it("resets the Authorization header") {
                    request.setValue("Basic dXNlcm5hbWU6cGFzc3dvcmQ=", forHTTPHeaderField: "Authorization")
                    request.setHTTPAuthorization(nil)

                    expect(request.HTTPAuthorization).to(beNil())
                }
            }

            context("when given a String") {
                it("sets the Authorization header to the given value") {
                    request.setHTTPAuthorization("Basic dXNlcm5hbWU6cGFzc3dvcmQ=")

                    expect(request.HTTPAuthorization).to(equal("Basic dXNlcm5hbWU6cGFzc3dvcmQ="))
                }
            }

            context("when given .BasicAuthentication") {
                it("sets the Authorization header with encoded username and password") {
                    let authentication: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")
                    request.setHTTPAuthorization(authentication)

                    expect(request.HTTPAuthorization).to(equal("Basic dXNlcm5hbWU6cGFzc3dvcmQ="))
                }
            }

            context("when given .AccessTokenAuthentication") {
                it("sets the Authorization header with access token and token type") {
                    let authentication: HTTPAuthentication = .AccessTokenAuthentication(OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType"))
                    request.setHTTPAuthorization(authentication)

                    expect(request.HTTPAuthorization).to(equal("tokenType accessToken"))
                }
            }
        }

        describe("-setHTTPBody") {
            context("when given nil") {
                it("resets the body") {
                    request.setHTTPBody(parameters: nil)

                    expect(request.HTTPBody).to(beNil())
                }
            }

            context("when given parameters") {
                it("sets the body with encoded parameters") {
                    let parameters: [String: AnyObject] = [
                        "#key1": "%value1",
                        "#key2": "%value2",
                        "key3": "value3[]",
                        "key4": ":&=;+!@#$()',*",
                        "key5.": "value.5",
                        "key6": "https://accounts.example.com/oauth/v2/foo/bar",
                        "key7": [
                            "one",
                            "two"
                        ],
                        "key8": [
                            "subkeyOne": "one",
                            "subkeyTwo": "two"
                        ]
                    ]

                    request.setHTTPBody(parameters: parameters)

                    let components = NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)?
                        .componentsSeparatedByString("&")
                        .sort { $0 < $1 }

                    expect(components?[0]).to(equal("%23key1=%25value1"))
                    expect(components?[1]).to(equal("%23key2=%25value2"))
                    expect(components?[2]).to(equal("key3=value3%5B%5D"))
                    expect(components?[3]).to(equal("key4=%3A%26%3D%3B%2B%21%40%23%24%28%29%27%2C%2A"))
                    expect(components?[4]).to(equal("key5.=value.5"))
                    expect(components?[5]).to(equal("key6=https%3A//accounts.example.com/oauth/v2/foo/bar"))
                    expect(components?[6]).to(equal("key7%5B%5D=one"))
                    expect(components?[7]).to(equal("key7%5B%5D=two"))
                }
            }
        }
    }
}
