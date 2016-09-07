import Heimdallr
import Nimble
import Quick
import Result

class OAuthAccessTokenSpec: QuickSpec {
    override func spec() {
        describe("-copy") {
            let accessToken = OAuthAccessToken(accessToken: "accessToken",
                                                 tokenType: "tokenType",
                                                 expiresAt: Date(timeIntervalSince1970: 0),
                                              refreshToken: "refreshToken")

            it("returns a copy of an access token") {
                let result: OAuthAccessToken = accessToken.copy()

                expect(result).toNot(beIdenticalTo(accessToken))
            }

            context("when providing a new access token") {
                let result = accessToken.copy(accessToken: "accessToken2")

                it("sets the provided access token on the new access token") {
                    expect(result.accessToken).to(equal("accessToken2"))
                }

                it("sets the original token type on the new access token") {
                    expect(result.tokenType).to(equal(accessToken.tokenType))
                }

                it("sets the original expiration date on the new access token") {
                    expect(result.expiresAt).to(equal(accessToken.expiresAt))
                }

                it("sets the original refreh token on the new access token") {
                    expect(result.refreshToken).to(equal(accessToken.refreshToken))
                }
            }

            context("when providing a new token type") {
                let result = accessToken.copy(tokenType: "tokenType2")

                it("sets the original access token on the new access token") {
                    expect(result.accessToken).to(equal(accessToken.accessToken))
                }

                it("sets the provided token type on the new access token") {
                    expect(result.tokenType).to(equal("tokenType2"))
                }

                it("sets the original expiration date on the new access token") {
                    expect(result.expiresAt).to(equal(accessToken.expiresAt))
                }

                it("sets the original refreh token on the new access token") {
                    expect(result.refreshToken).to(equal(accessToken.refreshToken))
                }
            }

            context("when providing a new expiration date") {
                let result = accessToken.copy(expiresAt: Date(timeIntervalSince1970: 1))

                it("sets the original access token on the new access token") {
                    expect(result.accessToken).to(equal(accessToken.accessToken))
                }

                it("sets the original token type on the new access token") {
                    expect(result.tokenType).to(equal(accessToken.tokenType))
                }

                it("sets the provided expiration date on the new access token") {
                    expect(result.expiresAt).to(equal(Date(timeIntervalSince1970: 1)))
                }

                it("sets the original refreh token on the new access token") {
                    expect(result.refreshToken).to(equal(accessToken.refreshToken))
                }
            }

            context("when providing a new refresh token") {
                let result = accessToken.copy(refreshToken: "refreshToken2")

                it("sets the original access token on the new access token") {
                    expect(result.accessToken).to(equal(accessToken.accessToken))
                }

                it("sets the original token type on the new access token") {
                    expect(result.tokenType).to(equal(accessToken.tokenType))
                }

                it("sets the original expiration date on the new access token") {
                    expect(result.expiresAt).to(equal(accessToken.expiresAt))
                }

                it("sets the provided refresh token on the new access token") {
                    expect(result.refreshToken).to(equal("refreshToken2"))
                }
            }
        }

        describe("<Equatable> ==") {
            it("returns true if access tokens are equal") {
                let lhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType")
                let rhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType")

                expect(lhs == rhs).to(beTrue())
            }

            it("returns false if access tokens are not equal") {
                let lhs = OAuthAccessToken(accessToken: "accessTokena", tokenType: "tokenType")
                let rhs = OAuthAccessToken(accessToken: "accessTokenb", tokenType: "tokenType")

                expect(lhs == rhs).to(beFalse())
            }

            it("returns false if token types are not equal") {
                let lhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenTypea")
                let rhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenTypeb")

                expect(lhs == rhs).to(beFalse())
            }

            it("returns false if expiration times are not equal") {
                let lhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType", expiresAt: Date(timeIntervalSinceNow: 1))
                let rhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType", expiresAt: Date(timeIntervalSinceNow: -1))

                expect(lhs == rhs).to(beFalse())
            }

            it("returns false if refresh tokens are not equal") {
                let lhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType", refreshToken: "refreshTokena")
                let rhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType", refreshToken: "refreshTokenb")

                expect(lhs == rhs).to(beFalse())
            }
        }

        describe("+decode") {
            context("without an expiration date") {
                it("creates a valid access token") {
                    let accessToken = OAuthAccessToken.decode([
                        "access_token": "accessToken" as AnyObject,
                        "token_type": "tokenType" as AnyObject
                    ])

                    expect(accessToken).toNot(beNil())
                    expect(accessToken?.accessToken).to(equal("accessToken"))
                    expect(accessToken?.tokenType).to(equal("tokenType"))
                    expect(accessToken?.expiresAt).to(beNil())
                    expect(accessToken?.refreshToken).to(beNil())
                }
            }
        }
    }
}
