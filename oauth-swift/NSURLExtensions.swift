//
//  NSURLExtensions.swift
//  oauth-swift
//
//  Created by Felix Jendrusch on 2/10/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Foundation

private func queryStringFromQueryParameters(queryParameters: [String: String]) -> String {
    var parts = [String]()
    for (name, value) in queryParameters {
        let encodedName = name.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let encodedValue = value.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        parts.append("\(encodedName!)=\(encodedValue!)")
    }

    return "&".join(parts)
}

public func NSURLByAppendingQueryParameters(URL: NSURL, queryParameters: [String: String]) -> NSURL? {
    let queryString = queryStringFromQueryParameters(queryParameters)
    return NSURL(string: "\(URL.absoluteString!)?\(queryString)")
}
