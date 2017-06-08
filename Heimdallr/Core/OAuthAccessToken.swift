import Result

/// An access token is used for authorizing requests to the resource endpoint.
@objc
public class OAuthAccessToken: NSObject {
    /// The access token.
    public let accessToken: String

    /// The acess token's type (e.g., Bearer).
    public let tokenType: String

    /// The access token's expiration date.
    public let expiresAt: Date?

    /// The refresh token.
    public let refreshToken: String?

    /// Initializes a new access token.
    ///
    /// - parameter accessToken: The access token.
    /// - parameter tokenType: The access token's type.
    /// - parameter expiresAt: The access token's expiration date.
    /// - parameter refreshToken: The refresh token.
    ///
    /// - returns: A new access token initialized with access token, type,
    ///     expiration date and refresh token.
    public init(accessToken: String, tokenType: String, expiresAt: Date? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }

    /// Copies the access token, using new values if provided.
    ///
    /// - parameter accessToken: The new access token.
    /// - parameter tokenType: The new access token's type.
    /// - parameter expiresAt: The new access token's expiration date.
    /// - parameter refreshToken: The new refresh token.
    ///
    /// - returns: A new access token with this access token's values for
    ///     properties where new ones are not provided.
    public func copy(accessToken: String? = nil, tokenType: String? = nil, expiresAt: Date?? = nil, refreshToken: String?? = nil) -> OAuthAccessToken {
        return OAuthAccessToken(accessToken: accessToken ?? self.accessToken,
                                tokenType: tokenType ?? self.tokenType,
                                expiresAt: expiresAt ?? self.expiresAt,
                                refreshToken: refreshToken ?? self.refreshToken)
    }
}

public func == (lhs: OAuthAccessToken, rhs: OAuthAccessToken) -> Bool {
    return lhs.accessToken == rhs.accessToken
        && lhs.tokenType == rhs.tokenType
        && lhs.expiresAt == rhs.expiresAt
        && lhs.refreshToken == rhs.refreshToken
}

extension OAuthAccessToken {
    public class func decode(_ json: [String: AnyObject]) -> OAuthAccessToken? {
        func toDate(_ timeIntervalSinceNow: TimeInterval?) -> Date? {
            return timeIntervalSinceNow.map { timeIntervalSinceNow in
                Date(timeIntervalSinceNow: timeIntervalSinceNow)
            }
        }

        guard let accessToken = json["access_token"] as? String,
            let tokenType = json["token_type"] as? String else {
            return nil
        }

        let expiresAt = (json["expires_in"] as? TimeInterval).flatMap(toDate)
        let refreshToken = json["refresh_token"] as? String

        return OAuthAccessToken(accessToken: accessToken, tokenType: tokenType,
                                expiresAt: expiresAt, refreshToken: refreshToken)
    }

    public class func decode(data: Data) -> OAuthAccessToken? {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)),
            let jsonDictionary = json as? [String: AnyObject] else {
            return nil
        }

        return decode(jsonDictionary)
    }
}
