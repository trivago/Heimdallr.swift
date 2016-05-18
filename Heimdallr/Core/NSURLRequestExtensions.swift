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

    // Taken from https://github.com/Alamofire/Alamofire/blob/master/Source/ParameterEncoding.swift#L176
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
            components.append((escape(key), escape("\(value)")))
        }

        return components
    }

    // Taken from https://github.com/Alamofire/Alamofire/blob/master/Source/ParameterEncoding.swift#L210
    private func escape(string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode + subDelimitersToEncode)

        var escaped = ""

        //==========================================================================================================
        //
        //  Batching is required for escaping due to an internal bug in iOS 8.1 and 8.2. Encoding more than a few
        //  hundred Chinense characters causes various malloc error crashes. To avoid this issue until iOS 8 is no
        //  longer supported, batching MUST be used for encoding. This introduces roughly a 20% overhead. For more
        //  info, please refer to:
        //
        //      - https://github.com/Alamofire/Alamofire/issues/206
        //
        //==========================================================================================================

        if #available(iOS 8.3, *) {
            escaped = string.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex

            while index != string.endIndex {
                let startIndex = index
                let endIndex = index.advancedBy(batchSize, limit: string.endIndex)
                let range = startIndex..<endIndex

                let substring = string.substringWithRange(range)

                escaped += substring.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? substring

                index = endIndex
            }
        }
        
        return escaped
    }
}
