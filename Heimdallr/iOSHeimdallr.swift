import Foundation
import Result
import UIKit

public extension Heimdallr {

    /// Requests an access token with the authorization code grant.
    ///
    /// **Note:** The completion closure may be invoked on any thread.
    ///
    /// - Parameters:
    ///   - url: The authorization code link.
    ///   - redirectURI: The redirect URI.
    ///   - scope: The authorization scope.
    ///   - completion: A cllback to invoke when the request completed.
    public func requestAccessToken(authorizationCodeURL url: URL, redirectURI: String, scope: String, completion: @escaping (Result<OAuthAccessToken, NSError>) -> Void) {
        requestAuthorizationCode(authorizationCodeURL: url, redirectURI: redirectURI, scope: scope) { [weak self] result in
            guard let strongSelf = self else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
                return
            }

            switch result {
            case let .success(code):
                strongSelf.requestAccessToken(authorizationCode: code.accessToken, redirectURI: redirectURI, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    /// Requests an access token with the Implicit grant.
    ///
    /// - Parameters:
    ///   - authorizationCodeURL: The authorization code link.
    ///   - redirectURI: The redirect URI.
    ///   - scope: The authorization scope.
    ///   - completion: A cllback to invoke when the request completed.
    public func requestAccessToken(implicitAuthorizationURL url: URL, redirectURI: String, scope: String, completion: @escaping (Result<OAuthAccessToken, NSError>) -> Void) {
        requestAuthorizationCode(authorizationCodeURL: url, redirectURI: redirectURI, scope: scope, responseType: "token", completion: completion)
    }

    /// Requests an authorization code.
    ///
    /// - Parameters:
    ///   - authorizationCodeURL: The authorization code link.
    ///   - redirectURI: The redirect URI.
    ///   - scope: The authorization scope.
    ///   - completion: A cllback to invoke when the request completed.
    public func requestAuthorizationCode(authorizationCodeURL url: URL, redirectURI: String, scope: String, completion: @escaping (Result<OAuthAccessToken, NSError>) -> Void) {
        requestAuthorizationCode(authorizationCodeURL: url, redirectURI: redirectURI, scope: scope, responseType: "code", completion: completion)
    }
    
    /// Handler for the redirect URI
    ///
    /// - Parameter url: The redirect URI.
    public func appOpen(authorizationCodeURL url: URL) {
        (authorizationCodeHandler as? OAuthAuthorizationCodeHandler)?.appOpen(authorizationCodeURL: url)
    }
    
    // MARK: - Helper

    private func requestAuthorizationCode(authorizationCodeURL url: URL, redirectURI: String, scope: String, responseType: String, completion: @escaping (Result<OAuthAccessToken, NSError>) -> Void) {
        var allParameters = credentials!.parameters
        allParameters["scope"] = scope
        allParameters["redirect_uri"] = redirectURI
        allParameters["response_type"] = responseType

        let queryItems = allParameters.map { URLQueryItem.init(name: $0, value: $1) }
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems

        let authorizationCodeHandler = OAuthAuthorizationCodeHandler()
        self.authorizationCodeHandler = authorizationCodeHandler

        authorizationCodeHandler.requestAuthorizationCode(url: urlComponents.url!, completion: completion)
    }
}
