//
//  NSURLRequestExtensionsSpec.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/12/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Quick
import Nimble

import Heimdall

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
                it("returns true if values match") {
                    let lhs: HTTPAuthentication = .Unknown(value: "value")
                    let rhs: HTTPAuthentication = .Unknown(value: "value")

                    expect(lhs == rhs).to(beTrue())
                }

                it("returns false if values do not match") {
                    let lhs: HTTPAuthentication = .Unknown(value: "valuea")
                    let rhs: HTTPAuthentication = .Unknown(value: "valueb")

                    expect(lhs == rhs).to(beFalse())
                }
            }

            context("Mixed") {
                it("returns false if authentication methods do not match") {
                    let lhs: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")
                    let rhs: HTTPAuthentication = .Unknown(value: "value")

                    expect(lhs == rhs).to(beFalse())
                }
            }
        }

        describe("-encode") {
            context("BasicAuthentication") {
                let authentication: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")

                it("returns the correctly encoded HTTP Authorization Header value") {
                    let result = authentication.toHTTPAuthorization()

                    expect(result).to(equal("Basic dXNlcm5hbWU6cGFzc3dvcmQ="))
                }
            }

            context("Unknown") {
                let authentication: HTTPAuthentication = .Unknown(value: "value")

                it("returns the value") {
                    let result = authentication.toHTTPAuthorization()

                    expect(result).to(equal("value"))
                }
            }
        }

        describe("+decode") {
            context("BasicAuthentication") {
                let authentication: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")

                it("returns the correctly decoded HTTP Authorization Header value") {
                    let result = HTTPAuthentication.fromHTTPAuthorization("Basic dXNlcm5hbWU6cGFzc3dvcmQ=")

                    expect(result).to(equal(authentication))
                }
            }

            context("Unknown") {
                let authentication: HTTPAuthentication = .Unknown(value: "value")

                it("returns the value wrapped as Unknown") {
                    let result = HTTPAuthentication.fromHTTPAuthorization("value")

                    expect(result).to(equal(authentication))
                }
            }
        }
    }
}

class NSURLRequestExtensionsSpec: QuickSpec {
    override func spec() {
        describe(".HTTPAuthorization") {
            it("returns nil if the HTTP Authorization Header is not set") {
                let request = NSURLRequest()

                expect(request.HTTPAuthorization).to(beNil())
            }

            it("returns an HTTPAuthentication if the HTTP Authorization Header is set") {
                let authentication: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")

                let request = NSMutableURLRequest()
                request.setValue("Basic dXNlcm5hbWU6cGFzc3dvcmQ=", forHTTPHeaderField: "Authorization")

                let result = request.HTTPAuthorization

                expect(result).to(equal(authentication))
            }
        }
    }
}

class NSMutableURLRequestExtensionsSpec: QuickSpec {
    override func spec() {
        describe("-setHTTPAuthorization") {
            it("sets the HTTP Authorization Header") {
                let authentication: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")

                let request = NSMutableURLRequest()
                request.setHTTPAuthorization(authentication)

                let result = request.valueForHTTPHeaderField("Authorization")

                expect(result).to(equal("Basic dXNlcm5hbWU6cGFzc3dvcmQ="))
            }
        }
    }
}
