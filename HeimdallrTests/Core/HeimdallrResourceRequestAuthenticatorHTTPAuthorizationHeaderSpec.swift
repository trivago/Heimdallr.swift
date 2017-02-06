import Heimdallr
import Nimble
import Quick

class HeimdallResourceRequestAuthenticatorHTTPAuthorizationHeaderSpec: QuickSpec {
    override func spec() {
        let resourceAuthenticator: HeimdallResourceRequestAuthenticatorHTTPAuthorizationHeader = HeimdallResourceRequestAuthenticatorHTTPAuthorizationHeader()

        describe("-authenticateResourceRequest:accessToken:") {
            it("sets the Authorization header") {
                let urlRequest = URLRequest(url: URL(string: "http://www.rheinfabrik.de")!)
                let accessToken = OAuthAccessToken(accessToken: "MTQzM2U3YTI3YmQyOWQ5YzQ0NjY4YTZkYjM0MjczYmZhNWI1M2YxM2Y1MjgwYTg3NDk3ZDc4ZGUzM2YxZmJjZQ", tokenType: "Bearer")
                let authenticatedRequest = resourceAuthenticator.authenticateResourceRequest(urlRequest, accessToken: accessToken)
                let authorizationHeaderValue = authenticatedRequest.value(forHTTPHeaderField: "Authorization")
                expect(authorizationHeaderValue).to(equal("Bearer MTQzM2U3YTI3YmQyOWQ5YzQ0NjY4YTZkYjM0MjczYmZhNWI1M2YxM2Y1MjgwYTg3NDk3ZDc4ZGUzM2YxZmJjZQ"))
            }
        }
    }
}
