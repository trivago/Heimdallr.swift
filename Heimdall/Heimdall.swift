import LlamaKit

public let HeimdallErrorDomain = "HeimdallErrorDomain"

/// The token endpoint responded with invalid data.
public let HeimdallErrorInvalidData = 1

/// The request could not be authorized (e.g., no refresh token available).
public let HeimdallErrorNotAuthorized = 2

/// The all-seeing and all-hearing guardian sentry of your application who
/// stands on the rainbow bridge network to authorize relevant requests.
@objc
public class Heimdall {
    private let tokenURL: NSURL
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
    private let httpClient: HeimdallHTTPClient

    /// Returns a Bool indicating whether the client's access token store
    /// currently holds an access token.
    ///
    /// **Note:** It's not checked whether the stored access token, if any, has
    ///     already expired.
    public var hasAccessToken: Bool {
        return accessToken != nil
    }

    /// Initializes a new client.
    ///
    /// :param: tokenURL The token endpoint URL.
    /// :param: credentials The OAuth client credentials. If both an identifier
    ///     and a secret are set, client authentication is performed via HTTP
    ///     Basic Authentication. Otherwise, if only an identifier is set, it is
    ///     encoded as parameter. Default: `nil` (unauthenticated client).
    /// :param: accessTokenStore The (persistent) access token store.
    ///     Default: `OAuthAccessTokenKeychainStore`.
    /// :param: httpClient The HTTP client that should be used for requesting
    ///     access tokens. Default: `HeimdallHTTPClientNSURLSession`.
    ///
    /// :returns: A new client initialized with the given token endpoint URL,
    ///     credentials and access token store.
    public init(tokenURL: NSURL, credentials: OAuthClientCredentials? = nil, accessTokenStore: OAuthAccessTokenStore = OAuthAccessTokenKeychainStore(), httpClient: HeimdallHTTPClient = HeimdallHTTPClientNSURLSession()) {
        self.tokenURL = tokenURL
        self.credentials = credentials
        self.accessTokenStore = accessTokenStore
        self.httpClient = httpClient
    }

    /// Requests an access token with the resource owner's password credentials.
    ///
    /// **Note:** The completion closure may be invoked on any thread.
    ///
    /// :param: username The resource owner's username.
    /// :param: password The resource owner's password.
    /// :param: completion A callback to invoke when the request completed.
    public func requestAccessToken(username: String, password: String, completion: Result<Void, NSError> -> ()) {
        requestAccessToken(.ResourceOwnerPasswordCredentials(username, password)) { result in
            completion(result.map { _ in return })
        }
    }

    /// Requests an access token with the given authorization grant.
    ///
    /// The client is authenticated via HTTP Basic Authentication if both an
    /// identifier and a secret are set in its credentials. Otherwise, if only
    /// an identifier is set, it is encoded as parameter.
    ///
    /// :param: grant The authorization grant (e.g., refresh).
    /// :param: completion A callback to invoke when the request completed.
    private func requestAccessToken(grant: OAuthAuthorizationGrant, completion: Result<OAuthAccessToken, NSError> -> ()) {
        let request = NSMutableURLRequest(URL: tokenURL)

        var parameters = grant.parameters
        if let credentials = credentials {
            if let secret = credentials.secret {
                request.setHTTPAuthorization(.BasicAuthentication(username: credentials.id, password: secret))
            } else {
                parameters["client_id"] = credentials.id
            }
        }

        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setHTTPBody(parameters: parameters)

        httpClient.sendRequest(request) { data, response, error in
            if let error = error {
                completion(failure(error))
            } else if (response as NSHTTPURLResponse).statusCode == 200 {
                if let accessToken = OAuthAccessToken.decode(data) {
                    self.accessToken = accessToken
                    completion(success(accessToken))
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not authorize grant", comment: ""),
                        NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected access token, got: %@.", comment: ""), NSString(data: data, encoding: NSUTF8StringEncoding) ?? "nil")
                    ]

                    let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorInvalidData, userInfo: userInfo)
                    completion(failure(error))
                }
            } else {
                if let error = OAuthError.decode(data) {
                    completion(failure(error.nsError))
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not authorize grant", comment: ""),
                        NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected error, got: %@.", comment: ""), NSString(data: data, encoding: NSUTF8StringEncoding) ?? "nil")
                    ]

                    let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorInvalidData, userInfo: userInfo)
                    completion(failure(error))
                }
            }
        }
    }

    /// Alters the given request by adding authentication with an access token.
    ///
    /// :param: request An unauthenticated NSURLRequest.
    /// :param: accessToken The access token to be used for authentication.
    ///
    /// :returns: The given request authorized via access token authentication.
    private func authenticateRequest(request: NSURLRequest, accessToken: OAuthAccessToken) -> NSURLRequest {
        var mutableRequest = request.mutableCopy() as NSMutableURLRequest
        mutableRequest.setHTTPAuthorization(.AccessTokenAuthentication(accessToken))
        return mutableRequest
    }

    /// Alters the given request by adding authentication, if possible.
    ///
    /// In case of an expired access token and the presence of a refresh token,
    /// automatically tries to refresh the access token.
    ///
    /// **Note:** If the access token must be refreshed, network I/O is
    ///     performed.
    ///
    /// **Note:** The completion closure may be invoked on any thread.
    ///
    /// :param: request An unauthenticated NSURLRequest.
    /// :param: completion A callback to invoke with the authenticated request.
    public func authenticateRequest(request: NSURLRequest, completion: Result<NSURLRequest, NSError> -> ()) {
        if let accessToken = accessToken {
            if accessToken.expiresAt != nil && accessToken.expiresAt < NSDate() {
                if let refreshToken = accessToken.refreshToken {
                    requestAccessToken(.RefreshToken(refreshToken)) { result in
                        completion(result.map { accessToken in
                            return self.authenticateRequest(request, accessToken: accessToken)
                        })
                    }
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not add authorization to request", comment: ""),
                        NSLocalizedFailureReasonErrorKey: NSLocalizedString("Access token expired, no refresh token available.", comment: "")
                    ]

                    let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorNotAuthorized, userInfo: userInfo)
                    completion(failure(error))
                }
            } else {
                let request = authenticateRequest(request, accessToken: accessToken)
                completion(success(request))
            }
        } else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not add authorization to request", comment: ""),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("Not authorized.", comment: "")
            ]

            let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorNotAuthorized, userInfo: userInfo)
            completion(failure(error))
        }
    }
}
