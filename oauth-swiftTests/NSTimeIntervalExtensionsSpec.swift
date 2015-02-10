//
//  NSTimeIntervalExtensionsSpec.swift
//  oauth-swift
//
//  Created by Tim Brückmann on 10.02.15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Quick
import Nimble

import oauth_swift

class NSTimeIntervalExtensionsSpec: QuickSpec {
    override func spec() {
        
        describe("-toString") {
            
            it("returns the time interval as string with one fraction digit") {
                let timeInterval: NSTimeInterval = 123355
                expect(timeInterval.toString()).to(equal("123355.0"))
            }
            
        }
        
    }
}
