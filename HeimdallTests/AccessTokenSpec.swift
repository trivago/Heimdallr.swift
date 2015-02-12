//
//  AccessTokenSpec.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/12/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Heimdall
import LlamaKit
import Nimble
import Quick

class AccessTokenSpec: QuickSpec {
    override func spec() {
        describe("<Equatable> ==") {
            it("returns true if access tokens are equal") {
                let lhs = AccessToken(accessToken: "accessToken", tokenType: "tokenType")
                let rhs = AccessToken(accessToken: "accessToken", tokenType: "tokenType")

                expect(lhs == rhs).to(beTrue())
            }

            it("returns false if access tokens are not equal") {
                let lhs = AccessToken(accessToken: "accessTokena", tokenType: "tokenType")
                let rhs = AccessToken(accessToken: "accessTokenb", tokenType: "tokenType")

                expect(lhs == rhs).to(beFalse())
            }

            it("returns false if token types are not equal") {
                let lhs = AccessToken(accessToken: "accessToken", tokenType: "tokenTypea")
                let rhs = AccessToken(accessToken: "accessToken", tokenType: "tokenTypeb")

                expect(lhs == rhs).to(beFalse())
            }

            it("returns false if expiration times are not equal") {
                let lhs = AccessToken(accessToken: "accessToken", tokenType: "tokenType", expiresAt: NSDate(timeIntervalSinceNow: 1))
                let rhs = AccessToken(accessToken: "accessToken", tokenType: "tokenType", expiresAt: NSDate(timeIntervalSinceNow: -1))

                expect(lhs == rhs).to(beFalse())
            }

            it("returns false if refresh tokens are not equal") {
                let lhs = AccessToken(accessToken: "accessToken", tokenType: "tokenType", refreshToken: "refreshTokena")
                let rhs = AccessToken(accessToken: "accessToken", tokenType: "tokenType", refreshToken: "refreshTokenb")
                
                expect(lhs == rhs).to(beFalse())
            }
        }
    }
}
