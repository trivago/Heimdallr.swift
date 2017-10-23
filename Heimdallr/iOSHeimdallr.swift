import Foundation
import Result

@available(iOS 9.0, *)
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
    public func requestAccessToken(authorizationCodeURL url: URL, redirectURI: String, scope: String, completion: @escaping (Result<Void, NSError>) -> Void) {
        var allParameters = credentials!.parameters
        allParameters["scope"] = scope
        allParameters["redirect_uri"] = redirectURI
        allParameters["response_type"] = "code"
        let queryItems = allParameters.map { URLQueryItem.init(name: $0, value: $1) }
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems

        let authorizationCodeHandler = AuthorizationCodeHandler()
        self.authorizationCodeHandler = authorizationCodeHandler
        authorizationCodeHandler.requestAuthorizationCode(url: urlComponents.url!) { [weak self] result in
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

    /// Handler for the redirect URI
    ///
    /// - Parameter url: The redirect URI.
    public func appOpen(authorizationCodeURL url: URL) {
        (authorizationCodeHandler as? AuthorizationCodeHandler)?.appOpen(authorizationCodeURL: url)
    }
}
