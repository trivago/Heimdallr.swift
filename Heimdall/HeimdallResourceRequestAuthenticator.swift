import Foundation

/// A request authenticator that can be used by Heimdall.
public protocol HeimdallResourceRequestAuthenticator {

    /// Authenticates the given request.
    ///
    /// :param: request The request to be authenticated.
    /// :param: accessToken The access token that should be used for
    ///     authenticating the request.
    ///
    /// :returns: The authenticated request.
    func authenticateResourceRequest(request: NSURLRequest, accessToken: OAuthAccessToken) -> NSURLRequest

}
