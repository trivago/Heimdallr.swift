import Foundation

/// A `HeimdallResourceRequestAuthenticator` which uses the HTTP `Authorization`
/// Header to authorize a request.
@objc
public class HeimdallResourceRequestAuthenticatorHTTPAuthorizationHeader: NSObject, HeimdallResourceRequestAuthenticator {

    public override init() {
    }

    /// Authenticates the given request by setting the HTTP `Authorization`
    /// header.
    ///
    /// - parameter request: The request to be authenticated.
    /// - parameter accessToken: The access token that should be used for
    ///     authenticating the request.
    ///
    /// - returns: The authenticated request.
    public func authenticateResourceRequest(_ request: URLRequest, accessToken: OAuthAccessToken) -> URLRequest {
        var mutableRequest = request
        mutableRequest.setHTTPAuthorization(.accessTokenAuthentication(accessToken))
        return mutableRequest
    }
}
