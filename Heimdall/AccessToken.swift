//
//  AccessToken.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/12/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Argo
import LlamaKit
import Runes

@objc
public class AccessToken {
    public let accessToken: String
    public let tokenType: String
    public let expiresAt: NSDate?
    public let refreshToken: String?

    public init(accessToken: String, tokenType: String, expiresAt: NSDate? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }
}

extension AccessToken: Equatable {}

public func == (lhs: AccessToken, rhs: AccessToken) -> Bool {
    return lhs.accessToken == rhs.accessToken
        && lhs.tokenType == rhs.tokenType
        && lhs.expiresAt == rhs.expiresAt
        && lhs.refreshToken == rhs.refreshToken
}

extension AccessToken: JSONDecodable {
    public class func create(accessToken: String)(tokenType: String)(expiresAt: NSDate?)(refreshToken: String?) -> AccessToken {
        return AccessToken(accessToken: accessToken, tokenType: tokenType, expiresAt: expiresAt, refreshToken: refreshToken)
    }

    public class func decode(data: NSData) -> AccessToken? {
        var error: NSError?

        if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) {
            return decode(JSONValue.parse(json))
        } else {
            return nil
        }
    }

    public class func decode(json: JSONValue) -> AccessToken? {
        return AccessToken.create
            <^> json <| "access_token"
            <*> json <| "token_type"
            <*> json <|? "expires_in"
            <*> json <|? "refresh_token"
    }
}
