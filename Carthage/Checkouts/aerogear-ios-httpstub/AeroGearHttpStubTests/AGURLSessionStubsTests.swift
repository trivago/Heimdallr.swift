/*
* JBoss, Home of Professional Open Source.
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import UIKit
import XCTest
import AeroGearHttpStub

class AGURLSessionStubsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        
        StubsManager.removeAllStubs()
    }
    
    func testStubWithNSURLSessionDefaultConfiguration() {
        // set up http stub
        StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
            return true
        }, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
            return StubResponse(data:NSData(), statusCode: 200, headers: ["Content-Type" : "text/json"])
        }))
        
        // async test expectation
        let registrationExpectation = expectationWithDescription("testStubWithNSURLSessionDefaultConfiguration");

        let request = NSMutableURLRequest(URL: NSURL(string: "http://server.com")!)
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            XCTAssertNil(error, "unexpected error")
            XCTAssertNotNil(data, "response should contain data")
            
            registrationExpectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testStubWithNSURLSessionDefaultConfigurationAndFalseRequestCondition() {
        // set up http stub
        var isMocked = false
        StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
            return false
            }, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
                isMocked = true
                return StubResponse(data:NSData(), statusCode: 200, headers: ["Content-Type" : "text/json"])
                }))
        
        // async test expectation
        let expectation = expectationWithDescription("testStubWithNSURLSessionDefaultConfiguration");
        
        let request = NSMutableURLRequest(URL: NSURL(string: "http://server.com")!)
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            XCTAssertFalse(isMocked, "not mocked")
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testStubWithNSURLSessionEphemeralConfiguration() {
        // set up http stub
        StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
            return true
        }, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
            return StubResponse(data:NSData(), statusCode: 200, headers: ["Content-Type" : "text/json"])
        }))
        
        // async test expectation
        let registrationExpectation = expectationWithDescription("testStubWithNSURLSessionEphemeralConfiguration");
        
        let request = NSMutableURLRequest(URL: NSURL(string: "http://server.com")!)
        
        let config = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            XCTAssertNil(error, "unexpected error")
            XCTAssertNotNil(data, "response should contain data")
            
            registrationExpectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testStubWithNSURLSessionSharedSession() {
        // set up http stub
        StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
            return true
            }, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
                return StubResponse(data:NSData(), statusCode: 200, headers: ["Content-Type" : "text/json"])
            }))
        
        // async test expectation
        let registrationExpectation = expectationWithDescription("testStubWithNSURLSessionSharedSession");
        
        let request = NSMutableURLRequest(URL: NSURL(string: "http://server.com")!)
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            XCTAssertNil(error, "unexpected error")
            XCTAssertNotNil(data, "response should contain data")
            
            registrationExpectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testStubWithLocalJsonFileInBundle() {
        StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
            return true
            }, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
                return StubResponse(filename: "stub.json", location:.Bundle(NSBundle(forClass: AGURLSessionStubsTests.self)), statusCode: 200, headers: ["Content-Type" : "text/json"])
            }))
        
        // async test expectation
        let registrationExpectation = expectationWithDescription("testStubWithNSURLSessionDefaultConfiguration");
        
        let request = NSMutableURLRequest(URL: NSURL(string: "http://server.com")!)
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            XCTAssertNil(error, "unexpected error")
            XCTAssertNotNil(data, "response should contain data")
            
            // verify mocked JSON response
            let response = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil) as [String: AnyObject]
            XCTAssertTrue(response["firstname"] as String == "John")
            XCTAssertTrue(response["lastname"] as String == "Smith")
            XCTAssertTrue(response["age"] as Int == 25)

            registrationExpectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testStubWithLocalJsonFileInDocuments() {
        // extract 'Documents' directory path
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
    
        // care for the case 'Documents' dir does not exist
        if (!NSFileManager.defaultManager().fileExistsAtPath(documentsPath)) {
            NSFileManager.defaultManager().createDirectoryAtPath(documentsPath, withIntermediateDirectories: true, attributes: nil, error: nil)
        }

        // copy stubbed json file located in the test bundle  to 'Documents directory to perform our test
        let filename = "stub.json"
        NSFileManager.defaultManager().copyItemAtPath(NSBundle(forClass: AGURLSessionStubsTests.self).pathForResource(filename.stringByDeletingPathExtension, ofType: filename.pathExtension)!, toPath: documentsPath.stringByAppendingPathComponent(filename),  error: nil)
        
        StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
            return true
            }, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
                return StubResponse(filename: filename, location:.Documents, statusCode: 200, headers: ["Content-Type" : "text/json"])
            }))
        
        // async test expectation
        let registrationExpectation = expectationWithDescription("testStubWithNSURLSessionDefaultConfiguration");
        
        let request = NSMutableURLRequest(URL: NSURL(string: "http://server.com")!)
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            XCTAssertNil(error, "unexpected error")
            XCTAssertNotNil(data, "response should contain data")
            
            // verify mocked JSON response
            let response = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil) as [String: AnyObject]
            XCTAssertTrue(response["firstname"] as String == "John")
            XCTAssertTrue(response["lastname"] as String == "Smith")
            XCTAssertTrue(response["age"] as Int == 25)
            
            registrationExpectation.fulfill()
            
            // delete file from 'Documents' directory
            NSFileManager.defaultManager().removeItemAtPath(documentsPath.stringByAppendingPathComponent(filename), error:nil)
            
        }
        
        task.resume()
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
