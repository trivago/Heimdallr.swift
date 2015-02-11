//
//  AccessTokenStorage.swift
//  Heimdall
//
//  Created by Tim Brückmann on 11.02.15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Foundation

public protocol AccessTokenStorage {
    func storeAccessToken(accessToken: AccessToken?)
    func retrieveAccessToken() -> AccessToken?
}
