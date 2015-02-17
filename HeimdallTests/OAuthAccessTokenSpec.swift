import Heimdall
import LlamaKit
import Nimble
import Quick

class OAuthAccessTokenSpec: QuickSpec {
    override func spec() {
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
                let lhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType", expiresAt: NSDate(timeIntervalSinceNow: 1))
                let rhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType", expiresAt: NSDate(timeIntervalSinceNow: -1))

                expect(lhs == rhs).to(beFalse())
            }

            it("returns false if refresh tokens are not equal") {
                let lhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType", refreshToken: "refreshTokena")
                let rhs = OAuthAccessToken(accessToken: "accessToken", tokenType: "tokenType", refreshToken: "refreshTokenb")
                
                expect(lhs == rhs).to(beFalse())
            }
        }
    }
}
