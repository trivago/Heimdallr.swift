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
    }
}

class NSURLRequestExtensionsSpec: QuickSpec {
    override func spec() {
        describe(".HTTPAuthorization") {
            it("returns nil if the Authorization header is not set") {
                let request = NSURLRequest()

                expect(request.HTTPAuthorization).to(beNil())
            }

            context("when the Authorization header is set to Basic Authentication") {
                it("returns .BasicAuthentication with decoded username and password") {
                    let authentication: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")

                    let request = NSMutableURLRequest()
                    request.setValue("Basic dXNlcm5hbWU6cGFzc3dvcmQ=", forHTTPHeaderField: "Authorization")

                    let result = request.HTTPAuthorization

                    expect(result).to(equal(authentication))
                }
            }

            context("when the Authorization header is set to an unknown authentication") {
                it("returns .Unknown with the header's value") {
                    let authentication: HTTPAuthentication = .Unknown(value: "value")

                    let request = NSMutableURLRequest()
                    request.setValue("value", forHTTPHeaderField: "Authorization")

                    let result = request.HTTPAuthorization

                    expect(result).to(equal(authentication))
                }
            }
        }
    }
}

class NSMutableURLRequestExtensionsSpec: QuickSpec {
    override func spec() {
        describe("-setHTTPAuthorization") {
            it("resets the Authorization header if given nil") {
                let authentication: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")

                let request = NSMutableURLRequest()
                request.setHTTPAuthorization(authentication)
                request.setHTTPAuthorization(nil)

                let result = request.valueForHTTPHeaderField("Authorization")

                expect(result).to(beNil())
            }

            context("when given .BasicAuthentication") {
                it("sets the Authorization header with encoded username and password") {
                    let authentication: HTTPAuthentication = .BasicAuthentication(username: "username", password: "password")

                    let request = NSMutableURLRequest()
                    request.setHTTPAuthorization(authentication)

                    let result = request.valueForHTTPHeaderField("Authorization")

                    expect(result).to(equal("Basic dXNlcm5hbWU6cGFzc3dvcmQ="))
                }
            }

            context("when given .Unknown") {
                it("sets the Authorization header with the value") {
                    let authentication: HTTPAuthentication = .Unknown(value: "value")

                    let request = NSMutableURLRequest()
                    request.setHTTPAuthorization(authentication)

                    let result = request.valueForHTTPHeaderField("Authorization")

                    expect(result).to(equal("value"))
                }
            }
        }
    }
}
