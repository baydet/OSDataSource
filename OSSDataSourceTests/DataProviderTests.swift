//
//  DataProviderTests.swift
//  OSDataSource
//
//  Created by Alexandr Evsyuchenya on 10/3/15.
//  Copyright © 2015 baydet. All rights reserved.
//

import XCTest
@testable import OSSDataSource

class DataProviderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDataProvider() {
        let objects = ["1", "2", "3"]
        let dataSource = DefaultDataProvider<String>(objects: objects)
        XCTAssert(dataSource.numberOfSections() == 1, "wrong sections count")
        XCTAssert(dataSource.numberOfItems(inSection: 0) == 3, "wrong sections count")
        dataSource.loadContent(nil)
        XCTAssert(dataSource.numberOfSections() == 0, "wrong sections count")
        XCTAssert(dataSource.numberOfItems(inSection: 0) == 0, "wrong sections count")

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    
}
