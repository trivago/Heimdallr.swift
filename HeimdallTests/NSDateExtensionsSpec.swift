//
//  NSDateExtensionsSpec.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/10/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import Nimble
import Quick

class NSDateExtensionsSpec: QuickSpec {
    override func spec() {
        let now = NSDate()
        let future = NSDate(timeIntervalSinceNow: 1)

        describe("<Equatable> ==") {
            it("returns true if dates are equal") {
                expect(now == now).to(beTrue())
            }

            it("returns false if dates are not equal") {
                expect(now == future).to(beFalse())
            }
        }

        describe("<Comparable> <=") {
            it("returns true if the first date is less than the second date") {
                expect(now <= future).to(beTrue())
            }

            it("returns true if the first date is equal to the second date") {
                expect(now <= now).to(beTrue())
            }

            it("returns false if the first date is greater than the second date") {
                expect(future <= now).to(beFalse())
            }
        }

        describe("<Comparable> <") {
            it("returns true if the first date is less than the second date") {
                expect(now < future).to(beTrue())
            }

            it("returns false if the first date is equal to the second date") {
                expect(now < now).to(beFalse())
            }

            it("returns false if the first date is greater than the second date") {
                expect(future < now).to(beFalse())
            }
        }
    }
}
