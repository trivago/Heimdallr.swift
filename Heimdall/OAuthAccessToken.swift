//
//  OAuthAccessToken.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/12/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Argo
import LlamaKit
import Runes

@objc
public class OAuthAccessToken {
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
