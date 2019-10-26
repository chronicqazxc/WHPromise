//
//  WHPromiseTests.swift
//  WHPromiseTests
//
//  Created by Hsiao, Wayne on 2019/10/26.
//  Copyright © 2019 Hsiao, Wayne. All rights reserved.
//

import XCTest
@testable import WHPromise

class WHPromiseTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func promisedString(_ str: String) -> Promise<String> {
        return Promise<String>(execute: { fulfill, reject in
            print("sleeping…")
            sleep(1)
            print("done sleeping")
            fulfill(str)
        })
    }
    
    func testInitWithCallBack() {
        let ex = expectation(description: "")
        let testValue = "testInitWithCallBack"
        let promise = promisedString(testValue)
        promise.then({ result in
            ex.fulfill()
            XCTAssertEqual(result, testValue)
        })
        
        wait(for: [ex], timeout: 10)
    }
    
    func testInitWithValue() {
        let ex = expectation(description: "")
        let testValue = 1234
        let promise = Promise<Int>(value: testValue)
        promise.then({ (result) in
            ex.fulfill()
            XCTAssertEqual(result, testValue)
        }) { (error) in
            print(error)
        }
        wait(for: [ex], timeout: 10)
    }
    
    func testInitWithError() {
        let ex = expectation(description: "")
        let promise = Promise<String>(error: MockError.responseError)
        promise.then({ (result) in
            
        }) { (error) in
            ex.fulfill()
            if let mockError = error as? MockError {
                XCTAssertEqual(MockError.responseError.hashValue, mockError.hashValue)
            } else {
                XCTFail("testInitWithError")
            }
        }
        
        wait(for: [ex], timeout: 10)
    }

    func testTransferPromise() {
        let ex = expectation(description: "")
        let promise = promisedString("test")
        var result = ""
        let expectation = "Result: 123"
        promise.then({ (value) -> Int in
            123
        }).then({ (result) in

        }).then({ (result, complete) -> Void in
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                complete("Result: \(result)")
            }
        }).then({
            result = $0
            ex.fulfill()
        })
        
        wait(for: [ex], timeout: 10)
        XCTAssertEqual(result, expectation)
    }
}
