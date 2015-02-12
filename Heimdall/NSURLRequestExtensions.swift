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
    case Unknown(value: String)

    public func toHTTPAuthorization() -> String? {
        switch self {
        case .BasicAuthentication(let username, let password):
            if let credentials = "\(username):\(password)"
                .dataUsingEncoding(NSASCIIStringEncoding)?
                .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0)) {
                return "Basic \(credentials)"
            } else {
                return nil
            }
        case .Unknown(let value):
            return value
        }
    }

    public static func fromHTTPAuthorization(value: String) -> HTTPAuthentication {
        if value.hasPrefix("Basic ") {
            let credentials = value.substringFromIndex(advance(value.startIndex, 6))
            if let data = NSData(base64EncodedString: credentials, options: NSDataBase64DecodingOptions(0)) {
                if let userPass = NSString(data: data, encoding: NSASCIIStringEncoding) as String? {
                    let result = split(userPass, { $0 == ":" }, maxSplit: 1)
                    if result.count == 2 {
                        return .BasicAuthentication(username: result[0], password: result[1])
                    }
                }
            }
        }

        return .Unknown(value: value)
    }
}

public func == (lhs: HTTPAuthentication, rhs: HTTPAuthentication) -> Bool {
    switch (lhs, rhs) {
    case (.BasicAuthentication(let lusername, let lpassword), .BasicAuthentication(let rusername, let rpassword)):
        return lusername == rusername && lpassword == rpassword
    case (.Unknown(let lvalue), .Unknown(let rvalue)):
        return lvalue == rvalue
    default:
        return false
    }
}

public extension NSURLRequest {
    public var HTTPAuthorization: HTTPAuthentication? {
        if let value = self.valueForHTTPHeaderField("Authorization") {
            return HTTPAuthentication.fromHTTPAuthorization(value)
        } else {
            return nil
        }
    }
}

public extension NSMutableURLRequest {
    // Declarations in extensions cannot override yet.
    public func setHTTPAuthorization(authentication: HTTPAuthentication?) {
        self.setValue(authentication?.toHTTPAuthorization(), forHTTPHeaderField: "Authorization")
    }
}
