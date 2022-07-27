//
//  GearRentTests.m
//  GearRentTests
//
//  Created by Edwin Delgado on 7/5/22.
//

#import <XCTest/XCTest.h>
#import "APIManager.h"
#import "float.h"

@interface GearRentTests : XCTestCase

@end

@implementation GearRentTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testFetchNearestCity{
    void(^completion)(NSString *, NSError *error) = ^void(NSString *response, NSError *error){
        if(error == nil){
            NSLog(@"API response: %@",response);
        } else{
            NSLog(@"%@", error);
        }
    };
    fetchNearestCity(47.730399537076686, -122.34805748173761, completion);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
