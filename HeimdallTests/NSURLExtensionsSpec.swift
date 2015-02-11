//
//  NSURLExtensionsSpec.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/10/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Heimdall
import Nimble
import Quick

class NSURLExtensionsSpec: QuickSpec {
    override func spec() {
        describe("NSURLByAppendingQueryParameters(NSURL, [String: String])") {
            it("returns the URL with query parameters appended") {
                let URL = NSURL(string: "http://rheinfabrik.de")
                let queryParameters = [ "%name": "#value" ]

                let result = NSURLByAppendingQueryParameters(URL!, queryParameters)

                expect(result).to(equal(NSURL(string: "http://rheinfabrik.de?%25name=%23value")))
            }
        }
    }
}
