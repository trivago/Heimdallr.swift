//
//  OAutchAccessTokenStorage.swift
//  Heimdall
//
//  Created by Tim Brückmann on 11.02.15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Foundation

public protocol OAuthAccessTokenStorage {
    func storeAccessToken(accessToken: OAuthAccessToken?)
    func retrieveAccessToken() -> OAuthAccessToken?
}
