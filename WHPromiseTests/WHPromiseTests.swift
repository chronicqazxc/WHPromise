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
    
    func testInitWithCallBack() {
        let ex = expectation(description: "")
        let testValue = "testInitWithCallBack"
        let promise = Promise<String> { (fulfill, reject) in
            DispatchQueue.global().async {
                fulfill(testValue)
            }
        }
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
            
        }).catch { (error) in
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
        let promise = Promise<String> { (fulfill, reject) in
            DispatchQueue.global().async {
                fulfill("foobar")
            }
        }
        let string = """
                        {"name": "Banana",
                           "points": 200,
                           "description": "A banana grown in Ecuador."
                        }
                    """
        promise.then({ (result, complete: @escaping (GroceryProduct)->Void) in
            let json = string.data(using: .utf8)
            let decoder = JSONDecoder()
            let products = try decoder.decode(GroceryProduct.self, from: json!)
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                complete(products)
            }
        }).then { (product) in
            ex.fulfill()
            XCTAssertEqual(product.name, "Banana")
        }.catch { (error) in
            print(error)
        }

        wait(for: [ex], timeout: 10)
    }
    
    func testCatchInSynchronous() {
        let ex = expectation(description: "")

        let promise = Promise<String>.init { (fulfill, _) in
            fulfill("hello")
        }
        
        promise.then { (result) -> Promise<Int> in
            XCTAssertEqual(result, "hello")
            throw MockError.responseError
        }.catch { (error) in
            if let mockError = error as? MockError {
                XCTAssertEqual(MockError.responseError.hashValue, mockError.hashValue)
                ex.fulfill()
            } else {
                XCTFail("testInitWithError")
            }
        }
        
        wait(for: [ex], timeout: 10)
    }
    
    func apiCall() throws -> Int {
        do {
            throw MockError.bodyError
        } catch {
            throw MockError.bodyError
        }
    }
    
    func testCatchInAsynchronous() {
        let ex = expectation(description: "")

        let promise = Promise<String>.init { (fulfill, _) in
            fulfill("hello")
        }
        
        promise.then { (result) -> [GroceryProduct] in
            let decoder = JSONDecoder()
            
            let string = """
                {"name": "Banana",
                    "points": 200,
                    "description": "A banana grown in Ecuador."},
                {"name", "Orange"}
            """
            let json = string.data(using: .utf8)
            let products = try decoder.decode([GroceryProduct].self, from: json!)
            return products
        }.then({ (result) in
            result.first
        }).catch { (error) in
            if let _ = error as? DecodingError {
                ex.fulfill()
            } else {
                XCTFail()
            }
        }
        
        wait(for: [ex], timeout: 10)
    }
}
