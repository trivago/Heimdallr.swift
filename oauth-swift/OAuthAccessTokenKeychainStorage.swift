//
//  OAuthAccessTokenKeychainStorage.swift
//  oauth-swift
//
//  Created by Tim Brückmann on 10.02.15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import KeychainAccess

@objc
public class OAuthAccessTokenKeychainStorage: OAuthAccessTokenStorage {
    
    let keychain: Keychain
    
    public init() {
        keychain = Keychain(service: "de.rheinfabrik.oauth-manager")
    }
    
    public func storeAccessToken(accessToken: OAuthAccessToken){
        keychain["access_token"] = accessToken.token
        keychain["token_type"] = accessToken.type
        if let expirationDate = accessToken.expiresAt {
            keychain["expires_at"] = expirationDate.timeIntervalSince1970.description
        }
        if let refreshToken = accessToken.refreshToken {
            keychain["refresh_token"] = refreshToken
        }
    }
    
    public func retrieveAccessToken() -> OAuthAccessToken? {
        let token = keychain["access_token"]
        let type = keychain["token_type"]
        let refreshToken = keychain["refresh_token"]
        
        var expirationDate: NSDate?
        if let expiresAt = keychain["expires_at"] {
            expirationDate = NSDate(timeIntervalSince1970: (expiresAt as NSString).doubleValue)
        }
        
        if let token = token {
            if let type = type {
                let accessToken = OAuthAccessToken(
                    token: token,
                    type: type,
                    expiresAt: expirationDate,
                    refreshToken: refreshToken)
                return accessToken
            }
        }
        
        return nil
    }
    
}
