//
//  NSURLRequestExtensions.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/12/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Foundation

public enum HTTPAuthentication: Equatable {
    case BasicAuthentication(username: String, password: String)
    case AccessTokenAuthentication(OAuthAccessToken)

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

public extension NSURLRequest {
    public var HTTPAuthorization: String? {
        return self.valueForHTTPHeaderField("Authorization")
    }
}

public extension NSMutableURLRequest {
    // Declarations in extensions cannot override yet.
    public func setHTTPAuthorization(value: String?) {
        self.setValue(value, forHTTPHeaderField: "Authorization")
    }

    public func setHTTPAuthorization(authentication: HTTPAuthentication) {
        self.setValue(authentication.value, forHTTPHeaderField: "Authorization")
    }
}
