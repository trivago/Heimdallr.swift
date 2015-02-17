import Foundation

/// An HTTP authentication is used for authorizing requests to either the token
/// or the resource endpoint.
public enum HTTPAuthentication: Equatable {
    /// HTTP Basic Authentication.
    ///
    /// :param: username The username.
    /// :param: password The password.
    case BasicAuthentication(username: String, password: String)

    /// Access Token Authentication.
    ///
    /// :param: _ The access token.
    case AccessTokenAuthentication(OAuthAccessToken)

    /// Returns the authentication encoded as `String` suitable for the HTTP
    /// `Authorization` header.
    private var value: String? {
        switch self {
        case .BasicAuthentication(let username, let password):
            if let credentials = "\(username):\(password)"
                .dataUsingEncoding(NSASCIIStringEncoding)?
                .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0)) {
                return "Basic \(credentials)"
            } else {
                return nil
            }
        case .AccessTokenAuthentication(let accessToken):
            return "\(accessToken.tokenType) \(accessToken.accessToken)"
        }
    }
}

public func == (lhs: HTTPAuthentication, rhs: HTTPAuthentication) -> Bool {
    switch (lhs, rhs) {
    case (.BasicAuthentication(let lusername, let lpassword), .BasicAuthentication(let rusername, let rpassword)):
        return lusername == rusername
            && lpassword == rpassword
    case (.AccessTokenAuthentication(let laccessToken), .AccessTokenAuthentication(let raccessToken)):
        return laccessToken == raccessToken
    default:
        return false
    }
}

private let HTTPRequestHeaderFieldAuthorization = "Authorization"

public extension NSURLRequest {
    /// Returns the HTTP `Authorization` header value or `nil` if not set.
    public var HTTPAuthorization: String? {
        return self.valueForHTTPHeaderField(HTTPRequestHeaderFieldAuthorization)
    }
}

public extension NSMutableURLRequest {
    /// Sets the HTTP `Authorization` header value.
    ///
    /// :param: value The value to be set or `nil`.
    ///
    /// TODO: Declarations in extensions cannot override yet.
    public func setHTTPAuthorization(value: String?) {
        self.setValue(value, forHTTPHeaderField: HTTPRequestHeaderFieldAuthorization)
    }

    /// Sets the HTTP `Authorization` header value using the given HTTP
    /// authentication.
    ///
    /// :param: authentication The HTTP authentication to be set.
    public func setHTTPAuthorization(authentication: HTTPAuthentication) {
        self.setHTTPAuthorization(authentication.value)
    }

    /// Sets the HTTP body using the given paramters encoded as query string.
    ///
    /// :param: parameters The parameters to be encoded or `nil`.
    ///
    /// TODO: Tests crash without named parameter.
    public func setHTTPBody(#parameters: [String: String]?) {
        if let parameters = parameters {
            var parts = [String]()
            for (name, value) in parameters {
                let encodedName = name.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
                let encodedValue = value.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
                parts.append("\(encodedName!)=\(encodedValue!)")
            }

            HTTPBody = "&".join(parts).dataUsingEncoding(NSUTF8StringEncoding)
        } else {
            HTTPBody = nil
        }
    }
}
