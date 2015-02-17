import Foundation

/// An authorization grant is a credential representing the resource owner's
/// authorization (to access its protected resources).
public enum OAuthAuthorizationGrant {
    /// A resource owner password credentials grant.
    ///
    /// :param: username The resource owner's username.
    /// :param: password The resource owner's password.
    case ResourceOwnerPasswordCredentials(String, String)

    /// A refresh token grant.
    ///
    /// :param: refreshToken The refresh token.
    case RefreshToken(String)

    /// Returns the grant's parameters.
    ///
    /// Except for `grant_type`, parameters are specific to each grant:
    ///
    /// - `.ResourceOwnerPasswordCredentials`: `username`, `password`
    /// - `.Refresh`: `refresh_token`
    public var parameters: [String: String] {
        switch self {
        case .ResourceOwnerPasswordCredentials(let username, let password):
            return [
                "grant_type": "password",
                "username": username,
                "password": password
            ]
        case .RefreshToken(let refreshToken):
            return [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken
            ]
        }
    }
}
