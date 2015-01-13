//
//  OSDataSourceTest.m
//  OSDataSource
//
//  Created by Alexandr Evsyuchenya on 1/13/15.
//  Copyright (c) 2015 baydet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OSDataSource.h"

@interface OSDataSourceTest : XCTestCase

@end

@interface OSDataSourceTest ()
@end

@implementation OSDataSourceTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testName
{

}

@end
