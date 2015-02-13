//
//  OAuthAuthorizationGrant.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/13/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Foundation

public enum OAuthAuthorizationGrant {
    case ResourceOwnerPasswordCredentials(String, String)

    case RefreshToken(String)

    public var parameters: [String: String] {
        switch self {
        case .ResourceOwnerPasswordCredentials(let username, let password):
            return [
                "grant_type": "password",
                "username": username,
                "password": password
            ]
        case .RefreshToken(let refreshToken):
            return [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken
            ]
        }
    }
}
