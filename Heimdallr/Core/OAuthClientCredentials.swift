import Foundation

/// Client credentials are used for authenticating with the token endpoint.
@objc
public class OAuthClientCredentials: NSObject {
    /// The client identifier.
    public let id: String

    /// The client secret.
    public let secret: String?

    /// Returns the client credentials as paramters.
    ///
    /// Includes the client identifier as `client_id` and the client secret,
    /// if set, as `client_secret`.
    public var parameters: [String: String] {
        var parameters = ["client_id": id]

        if let secret = secret {
            parameters["client_secret"] = secret
        }

        return parameters
    }

    /// Initializes new client credentials.
    ///
    /// - parameter id: The client identifier.
    /// - parameter secret: The client secret.
    ///
    /// - returns: New client credentials initialized with the given client
    ///     identifier and secret.
    public init(id: String, secret: String? = nil) {
        self.id = id
        self.secret = secret
    }
}
