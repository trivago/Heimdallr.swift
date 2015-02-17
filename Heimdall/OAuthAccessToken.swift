import Argo
import LlamaKit
import Runes

/// An access token is used for authorizing requests to the resource endpoint.
@objc
public class OAuthAccessToken {
    /// The access token.
    public let accessToken: String

    /// The acess token's type (e.g., Bearer).
    public let tokenType: String

    /// The access token's expiration date.
    public let expiresAt: NSDate?

    /// The refresh token.
    public let refreshToken: String?

    /// Initializes a new access token.
    ///
    /// :param: accessToken The access token.
    /// :param: tokenType The access token's type.
    /// :param: expiresAt The access token's expiration date.
    /// :param: refreshToken The refresh token.
    ///
    /// :returns: A new access token initialized with access token, type,
    ///     expiration date and refresh token.
    public init(accessToken: String, tokenType: String, expiresAt: NSDate? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }
}

extension OAuthAccessToken: Equatable {}

public func == (lhs: OAuthAccessToken, rhs: OAuthAccessToken) -> Bool {
    return lhs.accessToken == rhs.accessToken
        && lhs.tokenType == rhs.tokenType
        && lhs.expiresAt == rhs.expiresAt
        && lhs.refreshToken == rhs.refreshToken
}

extension OAuthAccessToken: JSONDecodable {
    public class func create(accessToken: String)(tokenType: String)(expiresAt: NSDate?)(refreshToken: String?) -> OAuthAccessToken {
        return OAuthAccessToken(accessToken: accessToken, tokenType: tokenType, expiresAt: expiresAt, refreshToken: refreshToken)
    }

    public class func decode(json: JSONValue) -> OAuthAccessToken? {
        return OAuthAccessToken.create
            <^> json <| "access_token"
            <*> json <| "token_type"
            <*> pure(json.find([ "expires_in" ]) >>- { json in
                    if let timeIntervalSinceNow = json.value() as NSTimeInterval? {
                        return NSDate(timeIntervalSinceNow: timeIntervalSinceNow)
                    } else {
                        return nil
                    }
                })
            <*> json <|? "refresh_token"
    }

    public class func decode(data: NSData) -> OAuthAccessToken? {
        var error: NSError?

        if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) {
            return decode(JSONValue.parse(json))
        } else {
            return nil
        }
    }
}
