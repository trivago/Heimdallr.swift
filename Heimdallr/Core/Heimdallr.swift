import Foundation
import Result

public let HeimdallrErrorDomain = "HeimdallrErrorDomain"

/// The token endpoint responded with invalid data.
public let HeimdallrErrorInvalidData = 1

/// The request could not be authorized (e.g., no refresh token available).
public let HeimdallrErrorNotAuthorized = 2

/// The all-seeing and all-hearing guardian sentry of your application who
/// stands on the rainbow bridge network to authorize relevant requests.
@objc open class Heimdallr: NSObject {
    public let tokenURL: URL
    private let credentials: OAuthClientCredentials?

    private let accessTokenStore: OAuthAccessTokenStore
    private var accessToken: OAuthAccessToken? {
        get {
            return accessTokenStore.retrieveAccessToken()
        }
        set {
            accessTokenStore.storeAccessToken(newValue)
        }
    }

    private let accessTokenParser: OAuthAccessTokenParser
    private let httpClient: HeimdallrHTTPClient

    /// The request authenticator that is used to authenticate requests.
    public let resourceRequestAuthenticator: HeimdallResourceRequestAuthenticator

    /// Returns a Bool indicating whether the client's access token store
    /// currently holds an access token.
    ///
    /// **Note:** It's not checked whether the stored access token, if any, has
    ///     already expired.
    public var hasAccessToken: Bool {
        return accessToken != nil
    }

    private var requestQueue = DispatchQueue(label: "com.trivago.Heimdallr.requestQueue", attributes: [])

    /// Initializes a new client.
    ///
    /// - parameter tokenURL: The token endpoint URL.
    /// - parameter credentials: The OAuth client credentials. If both an identifier
    ///     and a secret are set, client authentication is performed via HTTP
    ///     Basic Authentication. Otherwise, if only an identifier is set, it is
    ///     encoded as parameter. Default: `nil` (unauthenticated client).
    /// - parameter accessTokenStore: The (persistent) access token store.
    ///     Default: `OAuthAccessTokenKeychainStore`.
    /// - parameter accessTokenParser: The access token response parser.
    ///     Default: `OAuthAccessTokenDefaultParser`.
    /// - parameter httpClient: The HTTP client that should be used for requesting
    ///     access tokens. Default: `HeimdallrHTTPClientURLSession`.
    /// - parameter resourceRequestAuthenticator: The request authenticator that is
    ///     used to authenticate requests. Default:
    ///     `HeimdallResourceRequestAuthenticatorHTTPAuthorizationHeader`.
    ///
    /// - returns: A new client initialized with the given token endpoint URL,
    ///     credentials and access token store.
    @objc public init(tokenURL: URL, credentials: OAuthClientCredentials? = nil, accessTokenStore: OAuthAccessTokenStore = OAuthAccessTokenKeychainStore(), accessTokenParser: OAuthAccessTokenParser = OAuthAccessTokenDefaultParser(), httpClient: HeimdallrHTTPClient = HeimdallrHTTPClientURLSession(), resourceRequestAuthenticator: HeimdallResourceRequestAuthenticator = HeimdallResourceRequestAuthenticatorHTTPAuthorizationHeader()) {
        self.tokenURL = tokenURL
        self.credentials = credentials
        self.accessTokenStore = accessTokenStore
        self.accessTokenParser = accessTokenParser
        self.httpClient = httpClient
        self.resourceRequestAuthenticator = resourceRequestAuthenticator
    }

    /// Invalidates the currently stored access token, if any.
    ///
    /// Unlike `clearAccessToken` this will only invalidate the access token so
    /// that Heimdallr will try to refresh the token using the refresh token
    /// automatically.
    ///
    /// **Note:** Sets the access token's expiration date to
    ///     1 January 1970, GMT.
    open func invalidateAccessToken() {
        accessToken = accessToken?.copy(expiresAt: Date(timeIntervalSince1970: 0))
    }

    /// Clears the currently stored access token, if any.
    ///
    /// After calling this method the user needs to reauthenticate using
    /// `requestAccessToken`.
    open func clearAccessToken() {
        accessTokenStore.storeAccessToken(nil)
    }

    /// Requests an access token with the resource owner's password credentials.
    ///
    /// **Note:** The completion closure may be invoked on any thread.
    ///
    /// - parameter username: The resource owner's username.
    /// - parameter password: The resource owner's password.
    /// - parameter completion: A callback to invoke when the request completed.
    open func requestAccessToken(username: String, password: String, completion: @escaping (Result<Void, NSError>) -> Void) {
        requestAccessToken(grant: .resourceOwnerPasswordCredentials(username, password)) { result in
            completion(result.map { _ in return })
        }
    }

    /// Requests an access token with the given grant type URI and parameters
    ///
    /// **Note:** The completion closure may be invoked on any thread.
    ///
    /// - parameter grantType: The grant type URI of the extension grant
    /// - parameter parameters: The required parameters for the external grant
    /// - parameter completion: A callback to invoke when the request completed.
    open func requestAccessToken(grantType: String, parameters: [String: String], completion: @escaping (Result<Void, NSError>) -> Void) {
        requestAccessToken(grant: .extension(grantType, parameters)) { result in
            completion(result.map { _ in return })
        }
    }

    /// Requests an access token with the given authorization grant.
    ///
    /// The client is authenticated via HTTP Basic Authentication if both an
    /// identifier and a secret are set in its credentials. Otherwise, if only
    /// an identifier is set, it is encoded as parameter.
    ///
    /// - parameter grant: The authorization grant (e.g., refresh).
    /// - parameter completion: A callback to invoke when the request completed.
    private func requestAccessToken(grant: OAuthAuthorizationGrant, completion: @escaping (Result<OAuthAccessToken, NSError>) -> Void) {
        var request = URLRequest(url: tokenURL)

        var parameters = grant.parameters
        if let credentials = credentials {
            if let secret = credentials.secret {
                request.setHTTPAuthorization(.basicAuthentication(username: credentials.id, password: secret))
            } else {
                parameters["client_id"] = credentials.id
            }
        }

        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setHTTPBody(parameters: parameters as [String: AnyObject])

        httpClient.sendRequest(request) { data, response, error in
            if let error = error {
                completion(.failure(error as NSError))
            } else if (response as! HTTPURLResponse).statusCode == 200 {
                if let accessToken = try? self.accessTokenParser.parse(data: data!) {
                    self.accessToken = accessToken
                    completion(.success(accessToken))
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not authorize grant", comment: ""),
                        NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected access token, got: %@.", comment: ""), NSString(data: data!, encoding: String.Encoding.utf8.rawValue) ?? "nil"),
                    ]

                    let error = NSError(domain: HeimdallrErrorDomain, code: HeimdallrErrorInvalidData, userInfo: userInfo)
                    completion(.failure(error))
                }
            } else {
                if let data = data, let error = OAuthError.decode(data: data) {
                    completion(.failure(error.nsError))
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not authorize grant", comment: ""),
                        NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected error, got: %@.", comment: ""), NSString(data: data!, encoding: String.Encoding.utf8.rawValue) ?? "nil"),
                    ]

                    let error = NSError(domain: HeimdallrErrorDomain, code: HeimdallrErrorInvalidData, userInfo: userInfo)
                    completion(.failure(error))
                }
            }
        }
    }

    /// Alters the given request by adding authentication with an access token.
    ///
    /// - parameter request: An unauthenticated URLRequest.
    /// - parameter accessToken: The access token to be used for authentication.
    ///
    /// - returns: The given request authorized using the resource request
    ///     authenticator.
    private func authenticateRequest(_ request: URLRequest, accessToken: OAuthAccessToken) -> URLRequest {
        return resourceRequestAuthenticator.authenticateResourceRequest(request, accessToken: accessToken)
    }

    /// Alters the given request by adding authentication, if possible.
    ///
    /// In case of an expired access token and the presence of a refresh token,
    /// automatically tries to refresh the access token. If refreshing the
    /// access token fails, the access token is cleared.
    ///
    /// **Note:** If the access token must be refreshed, network I/O is
    ///     performed.
    ///
    /// **Note:** The completion closure may be invoked on any thread.
    ///
    /// **Note:** Calls to this function are automatically serialized
    ///
    /// - parameter request: An unauthenticated URLRequest.
    /// - parameter completion: A callback to invoke with the authenticated request.
    open func authenticateRequest(_ request: URLRequest, completion: @escaping (Result<URLRequest, NSError>) -> Void) {
        requestQueue.async {
            self.blockRequestQueue()
            self.authenticateRequestConcurrently(request, completion: completion)
        }
    }

    private func authenticateRequestConcurrently(_ request: URLRequest, completion: @escaping (Result<URLRequest, NSError>) -> Void) {
        if let accessToken = accessToken {
            if let expiration = accessToken.expiresAt, expiration < Date() {
                if let refreshToken = accessToken.refreshToken {
                    requestAccessToken(grant: .refreshToken(refreshToken)) { result in
                        completion(result.analysis(ifSuccess: { accessToken in
                            let authenticatedRequest = self.authenticateRequest(request, accessToken: accessToken)
                            return .success(authenticatedRequest)
                            }, ifFailure: { error in
                                if [HeimdallrErrorDomain, OAuthErrorDomain].contains(error.domain) {
                                    self.clearAccessToken()
                                }
                                return .failure(error)
                        }))
                        self.releaseRequestQueue()
                    }
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not add authorization to request", comment: ""),
                        NSLocalizedFailureReasonErrorKey: NSLocalizedString("Access token expired, no refresh token available.", comment: ""),
                    ]

                    let error = NSError(domain: HeimdallrErrorDomain, code: HeimdallrErrorNotAuthorized, userInfo: userInfo)
                    completion(.failure(error))
                    releaseRequestQueue()
                }
            } else {
                let request = authenticateRequest(request, accessToken: accessToken)
                completion(.success(request))
                releaseRequestQueue()
            }
        } else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not add authorization to request", comment: ""),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("Not authorized.", comment: ""),
            ]

            let error = NSError(domain: HeimdallrErrorDomain, code: HeimdallrErrorNotAuthorized, userInfo: userInfo)
            completion(.failure(error))
            releaseRequestQueue()
        }
    }

    private func blockRequestQueue() {
        requestQueue.suspend()
    }

    private func releaseRequestQueue() {
        requestQueue.resume()
    }
}
