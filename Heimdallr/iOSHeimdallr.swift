import Foundation
import Result
import UIKit

public typealias AuthorizationCodeCompletion = ((Result<String, NSError>) -> Void)

public extension Heimdallr {

    /// Requests an access token with the authorization code grant.
    ///
    /// **Note:** The completion closure may be invoked on any thread.
    ///
    /// - Parameters:
    ///   - url: The authorization code link.
    ///   - redirectURI: The redirect URI.
    ///   - scope: The authorization scope.
    ///   - completion: A callback to invoke when the request completed.
    public func requestAccessToken(authorizationCodeURL url: URL,
                                   redirectURI: String,
                                   scope: String,
                                   parameters: [String: String],
                                   completion: @escaping AccessTokenCompletion) {

        requestAuthorizationCode(authorizationCodeURL: url,
                                 redirectURI: redirectURI,
                                 scope: scope,
                                 parameters: parameters) { [weak self] result in

            guard let strongSelf = self else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
                return
            }

            switch result {
            case let .success(code):
                strongSelf.requestAccessToken(authorizationCode: code, redirectURI: redirectURI, completion: completion)
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
    ///   - completion: A callback to invoke when the request completed.
    public func requestAccessToken(implicitAuthorizationURL url: URL,
                                   redirectURI: String,
                                   scope: String,
                                   completion: @escaping AccessTokenCompletion) {
        requestAccessToken(implicitAuthorizationURL: url,
                           redirectURI: redirectURI,
                           scope: scope,
                           responseType: "token",
                           completion: completion)
    }

    /// Requests an authorization code.
    ///
    /// - Parameters:
    ///   - authorizationCodeURL: The authorization code link.
    ///   - redirectURI: The redirect URI.
    ///   - scope: The authorization scope.
    ///   - completion: A callback to invoke when the request completed.
    public func requestAuthorizationCode(authorizationCodeURL url: URL,
                                         redirectURI: String,
                                         scope: String,
                                         parameters: [String: String],
                                         completion: @escaping AuthorizationCodeCompletion) {
        requestAuthorizationCode(authorizationCodeURL: url,
                                 redirectURI: redirectURI,
                                 scope: scope,
                                 responseType: "code",
                                 parameters: parameters,
                                 completion: completion)
    }

    /// Handler for the redirect URI
    /// Needed for requesting authorization code without `SFAuthenticationSession`.
    /// `SFAuthenticationSession` is available since iOS 11.0
    ///
    /// - Parameter url: The redirect URI.
    public func appOpen(authorizationCodeURL url: URL) {
        authorizationCodeHandler.authCallback(url: url, error: nil)
    }

    // MARK: - Helper

    private func requestAccessToken(implicitAuthorizationURL url: URL,
                                    redirectURI: String,
                                    scope: String,
                                    responseType: String,
                                    completion: @escaping AccessTokenCompletion) {
        var allParameters: [String: String] = credentials?.parameters ?? [:]
        allParameters["scope"] = scope
        allParameters["redirect_uri"] = redirectURI
        allParameters["response_type"] = responseType

        let queryItems = allParameters.map { URLQueryItem.init(name: $0, value: $1) }
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems

        authorizationCodeHandler.requestAccessToken(url: urlComponents.url!, completion: completion)
    }

    private func requestAuthorizationCode(authorizationCodeURL url: URL,
                                          redirectURI: String,
                                          scope: String,
                                          responseType: String,
                                          parameters: [String: String],
                                          completion: @escaping AuthorizationCodeCompletion) {

        var allParameters: [String: String] = credentials?.parameters ?? [:]
        allParameters["scope"] = scope
        allParameters["redirect_uri"] = redirectURI
        allParameters["response_type"] = responseType

        allParameters.merge(parameters) { $0.0 }

        let queryItems = allParameters.map { URLQueryItem.init(name: $0, value: $1) }
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems

        authorizationCodeHandler.requestAuthorizationCode(url: urlComponents.url!, completion: completion)
    }
}
