import Foundation

/// A `HeimdallResourceRequestAuthenticator` which uses the HTTP `Authorization` 
/// Header to authorize a request.
@objc
public class HeimdallResourceRequestAuthenticatorHTTPAuthorizationHeader: HeimdallResourceRequestAuthenticator {
    
    public init() {
    }
    
    /// Authenticates the given request by setting the HTTP `Authorization`
    /// header.
    ///
    /// :param: request The request to be authenticated.
    /// :param: accessToken The access token that should be used for
    ///     authenticating the request.
    ///
    /// :returns: The authenticated request.
    public func authenticateResourceRequest(request: NSURLRequest, accessToken: OAuthAccessToken) -> NSURLRequest {
        var mutableRequest = request.mutableCopy() as! NSMutableURLRequest
        mutableRequest.setHTTPAuthorization(.AccessTokenAuthentication(accessToken))
        return mutableRequest
    }
    
}
