import Argo

/// See: The OAuth 2.0 Authorization Framework, 5.2 Error Response
///      <https://tools.ietf.org/html/rfc6749#section-5.2>

public let OAuthErrorDomain = "OAuthErrorDomain"
public let OAuthErrorInvalidRequest = 1
public let OAuthErrorInvalidClient = 2
public let OAuthErrorInvalidGrant = 3
public let OAuthErrorUnauthorizedClient = 4
public let OAuthErrorUnsupportedGrantType = 5
public let OAuthErrorInvalidScope = 6

public let OAuthURIErrorKey = "OAuthURIErrorKey"

public enum OAuthErrorCode: String {
    case InvalidRequest = "invalid_request"
    case InvalidClient = "invalid_client"
    case InvalidGrant = "invalid_grant"
    case UnauthorizedClient = "unauthorized_client"
    case UnsupportedGrantType = "unsupported_grant_type"
    case InvalidScope = "invalid_scope"
}

public extension OAuthErrorCode {
    public var intValue: Int {
        switch self {
        case .InvalidRequest:
            return OAuthErrorInvalidRequest
        case .InvalidClient:
            return OAuthErrorInvalidClient
        case .InvalidGrant:
            return OAuthErrorInvalidGrant
        case .UnauthorizedClient:
            return OAuthErrorUnauthorizedClient
        case .UnsupportedGrantType:
            return OAuthErrorUnsupportedGrantType
        case .InvalidScope:
            return OAuthErrorInvalidScope
        }
    }
}

extension OAuthErrorCode: Decodable {
    public static func decode(json: JSON) -> Decoded<OAuthErrorCode> {
        return String.decode(json).flatMap { code in
            return .fromOptional(OAuthErrorCode(rawValue: code))
        }
    }
}

public class OAuthError {
    public let code: OAuthErrorCode
    public let description: String?
    public let uri: String?

    public init(code: OAuthErrorCode, description: String? = nil, uri: String? = nil) {
        self.code = code
        self.description = description
        self.uri = uri
    }
}

public extension OAuthError {
    public var nsError: NSError {
        var userInfo = [String: AnyObject]()

        if let description = description {
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(description, comment: "")
        }

        if let uri = uri {
            userInfo[OAuthURIErrorKey] = uri
        }

        return NSError(domain: OAuthErrorDomain, code: code.intValue, userInfo: userInfo)
    }
}

extension OAuthError: Decodable {
    public class func create(code: OAuthErrorCode) -> String? -> String? -> OAuthError {
        return
            { description in
                { uri in
                    OAuthError(code: code, description: description, uri: uri)
                }
            }
    }

    public class func decode(json: JSON) -> Decoded<OAuthError> {
        return create
            <^> json <| "error"
            <*> json <|? "error_description"
            <*> json <|? "error_uri"
    }

    public class func decode(data: NSData) -> Decoded<OAuthError> {
        let json: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
        return Decoded<AnyObject>.fromOptional(json).flatMap(Argo.decode)
    }
}
