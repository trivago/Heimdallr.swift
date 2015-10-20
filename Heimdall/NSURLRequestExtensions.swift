import Foundation

/// An HTTP authentication is used for authorizing requests to either the token
/// or the resource endpoint.
public enum HTTPAuthentication: Equatable {
    /// HTTP Basic Authentication.
    ///
    /// - parameter username: The username.
    /// - parameter password: The password.
    case BasicAuthentication(username: String, password: String)

    /// Access Token Authentication.
    ///
    /// - parameter _: The access token.
    case AccessTokenAuthentication(OAuthAccessToken)

    /// Returns the authentication encoded as `String` suitable for the HTTP
    /// `Authorization` header.
    private var value: String? {
        switch self {
        case .BasicAuthentication(let username, let password):
            if let credentials = "\(username):\(password)"
                .dataUsingEncoding(NSASCIIStringEncoding)?
                .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)) {
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
    /// - parameter value: The value to be set or `nil`.
    ///
    /// TODO: Declarations in extensions cannot override yet.
    public func setHTTPAuthorization(value: String?) {
        self.setValue(value, forHTTPHeaderField: HTTPRequestHeaderFieldAuthorization)
    }

    /// Sets the HTTP `Authorization` header value using the given HTTP
    /// authentication.
    ///
    /// - parameter authentication: The HTTP authentication to be set.
    public func setHTTPAuthorization(authentication: HTTPAuthentication) {
        self.setHTTPAuthorization(authentication.value)
    }

    /// Sets the HTTP body using the given paramters encoded as query string.
    ///
    /// - parameter parameters: The parameters to be encoded or `nil`.
    ///
    /// TODO: Tests crash without named parameter.
    public func setHTTPBody(parameters parameters: [String: AnyObject]?) {
        if let parameters = parameters {
            var components: [(String, String)] = []
            for (key, value) in parameters {
                components += queryComponents(key, value)
            }
            let bodyString = components.map { "\($0)=\($1)" }.joinWithSeparator("&" )
            HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding)
        } else {
            HTTPBody = nil
        }
    }

    // Taken from https://github.com/Alamofire/Alamofire/blob/master/Source/ParameterEncoding.swift#L136
    private func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.appendContentsOf([(escapeQuery(key), escapeQuery("\(value)"))])
        }

        return components
    }

    private func escapeQuery(string: String) -> String {
        let legalURLCharactersToBeEscaped: CFStringRef = ":&=;+!@#$()',*"
        let charactersToLeaveUnescaped: CFStringRef = "[]."
        return CFURLCreateStringByAddingPercentEscapes(nil, string, charactersToLeaveUnescaped, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }

}
