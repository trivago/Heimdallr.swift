//
//  LlamaKitTests.swift
//  LlamaKitTests
//
//  Created by Rob Napier on 9/9/14.
//  Copyright (c) 2014 Rob Napier. All rights reserved.
//

import Foundation
import LlamaKit
import XCTest

class ResultTests: XCTestCase {
  let err = NSError(domain: "", code: 11, userInfo: nil)
  let err2 = NSError(domain: "", code: 12, userInfo: nil)

  func testSuccessIsSuccess() {
    let s: Result<Int,NSError> = success(42)
    XCTAssertTrue(s.isSuccess)
  }

  func testFailureIsNotSuccess() {
    let f: Result<Bool, NSError> = failure()
    XCTAssertFalse(f.isSuccess)
  }

  func testSuccessReturnsValue() {
    let s: Result<Int,NSError> = success(42)
    XCTAssertEqual(s.value!, 42)
  }

  func testSuccessReturnsNoError() {
    let s: Result<Int,NSError> = success(42)
    XCTAssert(s.error == nil)
  }

  func testFailureReturnsError() {
    let f: Result<Int, NSError> = failure(self.err)
    XCTAssertEqual(f.error!, self.err)
  }

  func testFailureReturnsNoValue() {
    let f: Result<Int, NSError> = failure(self.err)
    XCTAssertNil(f.value)
  }

  func testMapSuccessUnaryOperator() {
    let x: Result<Int, NSError> = success(42)
    let y = x.map(-)
    XCTAssertEqual(y.value!, -42)
  }

  func testMapFailureUnaryOperator() {
    let x: Result<Int, NSError> = failure(self.err)
    let y = x.map(-)
    XCTAssertNil(y.value)
    XCTAssertEqual(y.error!, self.err)
  }

  func testMapSuccessNewType() {
    let x: Result<String, NSError> = success("abcd")
    let y = x.map { countElements($0) }
    XCTAssertEqual(y.value!, 4)
  }

  func testMapFailureNewType() {
    let x: Result<String, NSError> = failure(self.err)
    let y = x.map { countElements($0) }
    XCTAssertEqual(y.error!, self.err)
  }

  func doubleSuccess(x: Int) -> Result<Int, NSError> {
    return success(x * 2)
  }

  func doubleFailure(x: Int) -> Result<Int, NSError> {
    return failure(self.err)
  }

  func testFlatMapSuccessSuccess() {
    let x: Result<Int, NSError> = success(42)
    let y = x.flatMap(doubleSuccess)
    XCTAssertEqual(y.value!, 84)
  }

  func testFlatMapSuccessFailure() {
    let x: Result<Int, NSError> = success(42)
    let y = x.flatMap(doubleFailure)
    XCTAssertEqual(y.error!, self.err)
  }

  func testFlatMapFailureSuccess() {
    let x: Result<Int, NSError> = failure(self.err2)
    let y = x.flatMap(doubleSuccess)
    XCTAssertEqual(y.error!, self.err2)
  }

  func testFlatMapFailureFailure() {
    let x: Result<Int, NSError> = failure(self.err2)
    let y = x.flatMap(doubleFailure)
    XCTAssertEqual(y.error!, self.err2)
  }

  func testDescriptionSuccess() {
    let x: Result<Int, NSError> = success(42)
    XCTAssertEqual(x.description, "Success: 42")
  }

  func testDescriptionFailure() {
    let x: Result<String, NSError> = failure()
    XCTAssert(x.description.hasPrefix("Failure: Error Domain= Code=0 "))
  }

  func testCoalesceSuccess() {
    let r: Result<Int, NSError> = success(42)
    let x = r ?? 43
    XCTAssertEqual(x, 42)
  }

  func testCoalesceFailure() {
    let x = failure() ?? 43
    XCTAssertEqual(x, 43)
  }

  private func makeTryFunction<T>(x: T, _ succeed: Bool = true)(error: NSErrorPointer) -> T {
    if !succeed {
      error.memory = NSError(domain: "domain", code: 1, userInfo: [:])
    }
    return x
  }

  func testTryTSuccess() {
    XCTAssertEqual(try(makeTryFunction(42 as Int?)) ?? 43, 42)
  }

  func testTryTFailure() {
    let result = try(makeTryFunction(nil as Int?, false))
    XCTAssertEqual(result ?? 43, 43)
    XCTAssert(result.description.hasPrefix("Failure: Error Domain=domain Code=1 "))
  }

  func testTryBoolSuccess() {
    XCTAssert(try(makeTryFunction(true)).isSuccess)
  }

  func testTryBoolFailure() {
    let result = try(makeTryFunction(false, false))
    XCTAssertFalse(result.isSuccess)
    XCTAssert(result.description.hasPrefix("Failure: Error Domain=domain Code=1 "))
  }
}
