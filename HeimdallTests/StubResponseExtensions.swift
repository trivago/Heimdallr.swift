//
//  StubResponseExtensions.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/10/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import AeroGearHttpStub
import Foundation

extension StubResponse {
    convenience init(filename: String, bundle: NSBundle, statusCode: Int = 200, headers: [String: String] = [ "Content-Type": "application/json" ]) {
        self.init(filename: filename, location: .Bundle(bundle), statusCode: statusCode, headers: headers)
    }
}
