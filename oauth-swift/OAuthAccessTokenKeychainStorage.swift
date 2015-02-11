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
    
    private let keychain: Keychain
    
    public init(service: String = "de.rheinfabrik.oauth-manager") {
        keychain = Keychain(service: service)
    }
    
    public func storeAccessToken(accessToken: OAuthAccessToken?) {
        keychain["access_token"] = accessToken?.token
        keychain["token_type"] = accessToken?.type
        keychain["expires_at"] = accessToken?.expiresAt?.timeIntervalSince1970.description
        keychain["refresh_token"] = accessToken?.refreshToken
    }
    
    public func retrieveAccessToken() -> OAuthAccessToken? {
        let token = keychain["access_token"]
        let type = keychain["token_type"]
        let refreshToken = keychain["refresh_token"]
        
        var expirationDate: NSDate?
        if let expiresAt = keychain["expires_at"] as NSString? {
            expirationDate = NSDate(timeIntervalSince1970: expiresAt.doubleValue)
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
