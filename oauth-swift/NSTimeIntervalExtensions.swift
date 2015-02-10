//
//  NSTimeIntervalExtensions.swift
//  oauth-swift
//
//  Created by Tim Brückmann on 10.02.15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Foundation

public extension NSTimeInterval {
    func toString() -> String {
        return String(format: "%.1f",self)
    }
}
