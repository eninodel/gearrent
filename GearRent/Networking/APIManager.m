//
//  APIManager.m
//  GearRent
//
//  Created by Edwin Delgado on 7/20/22.
//

#import "APIManager.h"
#import "Parse/Parse.h"
#import "GNGeoHash.h"
#import "CoreLocation/CoreLocation.h"
#import "Edge.h"

@implementation APIManager

+ (void)fetchListingsWithCoordinates:(NSArray *)coordinates completion:(void(^)(NSArray *listings, NSError *error))completion{
    // Find all the geohashes within the polygon and return nil if no geohashes with precision 7 exist
    NSMutableSet *geohashesWithinPolygon = [[NSMutableSet alloc] init];
    for(int i = 1; i <= 7; i ++){
        geohashesWithinPolygon = [self findAllGeohashesWithinPolygon:coordinates precision:i];
        if([geohashesWithinPolygon count] > 0){
            break;
        }
    }
    if([geohashesWithinPolygon count] == 0){
        NSError *error = [NSError errorWithDomain:@"someDomain" code:404 userInfo:@{@"Error reason": @"Polygon too small"}];
        completion(nil, error);
    }
    [PFCloud callFunctionInBackground:@"getListingsWithGeohashes"
                       withParameters:@{@"geohashes": [geohashesWithinPolygon allObjects]}
                                block:^(NSArray *listings, NSError *error) {
      if (!error) {
          NSLog(@"%@", listings); // complete with listings after
      }
    }];
}

+ (NSMutableSet *)findAllGeohashesWithinPolygon:(NSArray *)coordinates precision:(int)precision {
    NSMutableSet *uncheckedGeohashes = [[NSMutableSet alloc] init];
    NSMutableSet *insideGeohashes = [[NSMutableSet alloc] init];
    NSMutableSet *outsideGeohashes = [[NSMutableSet alloc] init];
    for(int i = 0; i < coordinates.count; i++){
        CLLocation *location = (CLLocation *) coordinates[i];
        GNGeoHash *gh = [GNGeoHash withCharacterPrecision: location.coordinate.latitude andLongitude:location.coordinate.longitude andNumberOfCharacters:precision];
        [uncheckedGeohashes addObject:gh];
    }
    while (uncheckedGeohashes.count > 0) {
        GNGeoHash *currGH = (GNGeoHash *)[uncheckedGeohashes allObjects][0];
        if([self polygonContainsGeohash:coordinates geohash:currGH]){
            [insideGeohashes addObject:currGH];
            NSArray *neighbors = [currGH getAdjacent];
            for(GNGeoHash *neighbor in neighbors){
                if(![insideGeohashes containsObject:neighbor] && ![outsideGeohashes containsObject:neighbor] && ![uncheckedGeohashes containsObject:neighbor]){
                    [uncheckedGeohashes addObject:neighbor];
                }
            }
        } else{
            [outsideGeohashes addObject:currGH];
        }
    }
    return insideGeohashes;
}

+ (BOOL)polygonContainsGeohash:(NSArray *)coordinates geohash:(GNGeoHash *)geohash {
    NSMutableArray *currGHCorners = [self getFourConersOfGeohash:geohash];
    for(int i = 0; i < currGHCorners.count; i ++){
        CLLocation *currCorner = currGHCorners[i];
        if(![self polygonContainsPoint:coordinates point:currCorner]){
            return NO;
        }
    }
    return YES;
}

+ (BOOL)polygonContainsPoint:(NSArray *)coordinates point:(CLLocation *)point {
    BOOL inside = NO;
    NSMutableArray *edges = [self getPolygonEdges:coordinates];
    for(int i = 0; i < edges.count; i ++){
        Edge *curr = (Edge *)edges[i];
        CLLocation *lowestPoint = curr.start; // A
        CLLocation *highestPoint = curr.end; // B
        if(lowestPoint.coordinate.latitude > highestPoint.coordinate.latitude){
            lowestPoint = curr.end;
            highestPoint = curr.start;
        }
        if([self isPointSameHeightAsEdge:curr point:point]){
            point = [[CLLocation alloc] initWithLatitude:point.coordinate.latitude + DBL_EPSILON longitude:point.coordinate.longitude];
        }
        if(point.coordinate.latitude <= highestPoint.coordinate.latitude && point.coordinate.latitude >= lowestPoint.coordinate.latitude && point.coordinate.longitude <= MAX(lowestPoint.coordinate.longitude, highestPoint.coordinate.longitude)){
            if(point.coordinate.longitude >= MIN(lowestPoint.coordinate.longitude, highestPoint.coordinate.longitude)){
                double slopeOfEdge = 0.0;
                double slopeOfPoint = 0.0;
                @try {
                    slopeOfEdge = (highestPoint.coordinate.latitude - lowestPoint.coordinate.latitude) / (highestPoint.coordinate.longitude - lowestPoint.coordinate.longitude);
                } @catch (NSException *exception) {
                    slopeOfEdge = DBL_MAX;
                }
                @try{
                    slopeOfPoint = (point.coordinate.latitude - lowestPoint.coordinate.latitude) / (point.coordinate.longitude - lowestPoint.coordinate.longitude);
                } @catch (NSException *exception){
                    slopeOfPoint = DBL_MAX;
                }
                if(slopeOfPoint >= slopeOfEdge){ // ray intersects with edge
                    inside = !inside;
                }
            }else{ // ray intersects with edge
                inside = !inside;
            }
        }
    }
    return inside;
}

+ (BOOL)isPointSameHeightAsEdge:(Edge *)edge point:(CLLocation *)point {
    if(fabs(point.coordinate.latitude - edge.start.coordinate.latitude) < DBL_EPSILON ||
       fabs(point.coordinate.latitude - edge.end.coordinate.latitude) < DBL_EPSILON){
        return YES;
    }
    return NO;
}

+ (NSMutableArray *)getPolygonEdges:(NSArray *)coordinates {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for(int i = 0; i < coordinates.count; i ++){
        Edge *edge = [[Edge alloc] init];
        edge.start = (CLLocation *)coordinates[i];
        edge.end = (CLLocation *)coordinates[(i + 1)%coordinates.count];
        [result addObject:edge];
    }
    return result;
}

+ (NSMutableArray *)getFourConersOfGeohash:(GNGeoHash *)geohash {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    GNWGS84Point *upperLeftPoint =  [geohash.boundingBox getUpperLeft];
    GNWGS84Point *lowerRightPoint = [geohash.boundingBox getLowerRight];
    [result addObject:[[CLLocation alloc] initWithLatitude:upperLeftPoint.latitude longitude:upperLeftPoint.longitude]];
    [result addObject:[[CLLocation alloc] initWithLatitude:lowerRightPoint.latitude longitude:lowerRightPoint.longitude]];
    [result addObject:[[CLLocation alloc] initWithLatitude:lowerRightPoint.latitude longitude:upperLeftPoint.longitude]];
    [result addObject:[[CLLocation alloc] initWithLatitude:upperLeftPoint.latitude longitude:lowerRightPoint.longitude]];
    return result;
}

@end
