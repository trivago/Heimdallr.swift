//
//  OAuthClientCredentials.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/13/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Foundation

@objc
public class OAuthClientCredentials {
    public let id: String
    public let secret: String?

    public var parameters: [String: String] {
        var parameters = [ "client_id": id ]

        if let secret = secret {
            parameters["client_secret"] = secret
        }

        return parameters
    }

    public init(id: String, secret: String? = nil) {
        self.id = id
        self.secret = secret
    }
}
