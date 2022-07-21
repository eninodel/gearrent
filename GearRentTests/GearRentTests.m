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

- (void)testPolygonContainsPoint{
//    NSMutableArray<CLLocation *> *coordinates = [NSMutableArray<CLLocation *> new];
//    [coordinates addObject:[[CLLocation alloc] initWithLatitude:49.342796 longitude:-127.278627]];
//    [coordinates addObject:[[CLLocation alloc] initWithLatitude:49.342796 longitude:-101.685734]];
//    [coordinates addObject:[[CLLocation alloc] initWithLatitude:37.670506 longitude:-101.685734]];
//    [coordinates addObject:[[CLLocation alloc] initWithLatitude:37.670506 longitude:-127.278627]];
    
    NSMutableArray<CLLocation *> *coordinates = [NSMutableArray<CLLocation *> new];
    double topLeftLat = 47.629015;
    double topLeftLong = -122.331929;
    double botRightLat = 47.612416;
    double botRightLong = -122.301203;
    [coordinates addObject:[[CLLocation alloc] initWithLatitude:topLeftLat longitude:topLeftLong]];
    [coordinates addObject:[[CLLocation alloc] initWithLatitude:topLeftLat longitude:botRightLong]];
    [coordinates addObject:[[CLLocation alloc] initWithLatitude:botRightLat longitude:botRightLong]];
    [coordinates addObject:[[CLLocation alloc] initWithLatitude:botRightLat longitude:topLeftLong]];
    
    CLLocation *point = [[CLLocation alloc] initWithLatitude:botRightLat + 0.1 longitude:botRightLong - 0.1];
    
    NSMutableSet<GNGeoHash *> *geohashes = [APIManager findAllGeohashesWithinPolygon:coordinates precision:6];
    for(GNGeoHash * geohash in [geohashes allObjects]){
        NSLog(@"%@", [geohash toBase32]);
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
