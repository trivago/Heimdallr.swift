//
//  OAuthAccessTokenStore.swift
//  Heimdall
//
//  Created by Tim Brückmann on 11.02.15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Foundation

/// A (persistent) access token store.
public protocol OAuthAccessTokenStore {
    /// Stores the given access token.
    ///
    /// Given nil, it resets the currently stored access token, if any.
    ///
    /// :param: accessToken The access token to be stored.
    func storeAccessToken(accessToken: OAuthAccessToken?)

    /// Retrieves the currently stored access token.
    ///
    /// :returns: The currently stored access token.
    func retrieveAccessToken() -> OAuthAccessToken?
}
