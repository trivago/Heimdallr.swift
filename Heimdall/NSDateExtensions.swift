//
//  NSDateExtensions.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/10/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Foundation

extension NSDate: Comparable {}

public func == (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.isEqualToDate(rhs)
}

public func <= (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs < rhs || lhs == rhs
}

public func >= (lhs: NSDate, rhs: NSDate) -> Bool {
    return rhs <= lhs
}

public func < (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == NSComparisonResult.OrderedAscending
}

public func > (lhs: NSDate, rhs: NSDate) -> Bool {
    return rhs < lhs
}
