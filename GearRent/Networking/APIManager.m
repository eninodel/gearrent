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
#import "Item.h"
#import "Foundation/Foundation.h"

static int const kMaxGeoHashPrecision = 7;

@implementation APIManager

void fetchListingsWithCoordinates(NSArray<CLLocation *> *polygonCoordinates, void(^completion)(NSArray<Item *> *, NSError *error)){
    // Find all the geohashes within the polygon and return nil if no geohashes with precision 7 exist
    NSMutableSet<GNGeoHash *> *geohashesWithinPolygon = [NSMutableSet<GNGeoHash *> new];
    for(int i = 1; i <= kMaxGeoHashPrecision; i ++) {
        geohashesWithinPolygon = [APIManager findAllGeohashesWithinPolygon:polygonCoordinates precision:i];
        if([geohashesWithinPolygon count] > 0) {
            break;
        }
    }
    if([geohashesWithinPolygon count] == 0) {
        NSError *error = [NSError errorWithDomain:@"someDomain" code:404 userInfo:@{@"Error reason": @"Polygon too small"}];
        completion(nil, error);
        return;
    }
    NSArray *geohashesArray = [geohashesWithinPolygon allObjects];
    NSMutableArray<NSString *> *geohashesStringArray = [NSMutableArray<NSString *> new];
    for(int i = 0; i < geohashesArray.count; i++) {
        [geohashesStringArray addObject:[geohashesArray[i] toBase32]];
    }
    [PFCloud callFunctionInBackground:@"getListingsWithGeohashes"
                       withParameters:@{@"geohashes": geohashesStringArray}
                                block:^(NSArray *listings, NSError *error) {
      if (!error) {
          NSMutableArray<Item *> *allListings = [NSMutableArray<Item *> new];
          NSArray<NSArray<Item *> *> *results = listings;
          for(int i = 0; i < results.count; i ++){
              for(int j = 0; j < results[i].count; j ++){
                  [allListings addObject:results[i][j]];
              }
          }
          completion(allListings,nil);
      } else {
          NSLog(@"END: Error in calling cloud function");
          NSError *error = [NSError errorWithDomain:@"someDomain" code:404 userInfo:@{@"Error reason": @"END: Error in calling cloud function"}];
          completion(nil, error);
      }
    }];
}

void fetchNearestCity(double lat, double longitude, void(^completion)(NSString *, NSError *error)){
    @autoreleasepool{
        NSDictionary *headers = @{ @"X-RapidAPI-Key": @"4ee4de8731msh81f644e471716bbp14ba33jsnae748db48874",
                               @"X-RapidAPI-Host": @"forward-reverse-geocoding.p.rapidapi.com" };
        NSString *requestURL = [NSString stringWithFormat:@"https://forward-reverse-geocoding.p.rapidapi.com/v1/reverse?lat=%f&lon=%f&accept-language=en&polygon_threshold=0.0&zoom=10", lat ,longitude];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: requestURL]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
        [request setHTTPMethod:@"GET"];
        [request setAllHTTPHeaderFields:headers];

        NSURLSession *session = [NSURLSession sharedSession];
        __block BOOL done = NO;
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    done = YES;
                                                    if (error) {
                                                        completion(nil, error);
                                                    } else {
                                                        NSString *strISOLatin = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
                                                        NSData *dataUTF8 = [strISOLatin dataUsingEncoding:NSUTF8StringEncoding];
                                                        id dict = [NSJSONSerialization JSONObjectWithData:dataUTF8 options:0 error:&error];
                                                        if (dict != nil) {
                                                            completion([APIManager getSmallestEntity:dict], nil);
                                                        } else {
                                                            NSLog(@"Error: %@", error);
                                                            completion(nil, error);
                                                        }
                                                    }
                                                }];
        [dataTask resume];
        while (!done) {
            NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:0.1];
            [[NSRunLoop currentRunLoop] runUntilDate:date];
        }
    }
}

+ (NSString *)getSmallestEntity:(NSDictionary *)dict{
    NSMutableArray<NSString *> *possibleKeys = [NSMutableArray<NSString *> new];
    [possibleKeys addObject:@"town"];
    [possibleKeys addObject:@"city"];
    [possibleKeys addObject:@"county"];
    for(NSString * key in possibleKeys){
        NSString *val = (NSString *) [[dict valueForKey:@"address"] valueForKey:key];
        if(val != nil){
            return val;
        }
    }
    return nil;
}

+ (NSMutableSet<GNGeoHash *> *)findAllGeohashesWithinPolygon:(NSArray<CLLocation *> *)polygonCoordinates precision:(int)precision {
    // Finds all the geohashes within a polygon.
    // Objective-c adaptation of https://gis.stackexchange.com/a/281017
    NSMutableSet<GNGeoHash *> *uncheckedGeohashes = [NSMutableSet<GNGeoHash *> new];
    NSMutableSet<GNGeoHash *> *insideGeohashes = [NSMutableSet<GNGeoHash *> new];
    NSMutableSet<GNGeoHash *> *outsideGeohashes = [NSMutableSet<GNGeoHash *> new];
    for(int i = 0; i < polygonCoordinates.count; i++) {
        CLLocation *location = polygonCoordinates[i];
        GNGeoHash *gh = [GNGeoHash withCharacterPrecision:location.coordinate.latitude andLongitude:location.coordinate.longitude andNumberOfCharacters:precision];
        NSArray<GNGeoHash *> *adjacentGeohashes = [gh getAdjacent];
        for(GNGeoHash * geohash in adjacentGeohashes) {
            if([self polygonContainsGeohash:polygonCoordinates geohash:geohash]) {
                [uncheckedGeohashes addObject:geohash];
            }
        }
    }
    while (uncheckedGeohashes.count > 0) {
        GNGeoHash *currGH = [uncheckedGeohashes anyObject];
        [uncheckedGeohashes removeObject:currGH];
        if([self polygonContainsGeohash:polygonCoordinates geohash:currGH]) {
            [insideGeohashes addObject:currGH];
            NSArray *neighbors = [currGH getAdjacent];
            for(GNGeoHash *neighbor in neighbors) {
                if(![insideGeohashes containsObject:neighbor] && ![outsideGeohashes containsObject:neighbor] && ![uncheckedGeohashes containsObject:neighbor] && [self polygonContainsGeohash:polygonCoordinates geohash:neighbor]) {
                    [uncheckedGeohashes addObject:neighbor];
                }
            }
        } else {
            [outsideGeohashes addObject:currGH];
        }
    }
    return insideGeohashes;
}

+ (BOOL)polygonContainsGeohash:(NSArray<CLLocation *> *)polygonCoordinates geohash:(GNGeoHash *)geohash {
    NSMutableArray<CLLocation *> *currGHCorners = [self getFourCornersOfGeohash:geohash];
    for(int i = 0; i < currGHCorners.count; i ++) {
        CLLocation *currCorner = currGHCorners[i];
        if(![self polygonContainsPoint:polygonCoordinates point:currCorner]) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)polygonContainsPoint:(NSArray<CLLocation *> *)polygonCoordinates point:(CLLocation *)point {
    // Determines if a polygon contains a given point using ray casting algorithim.
    // Objective-C adaptation of http://philliplemons.com/posts/ray-casting-algorithm
    // TODO: Modify function to work on lat/long boundaries
    BOOL inside = NO;
    NSMutableArray<Edge *> *edges = [self getPolygonEdges:polygonCoordinates];
    for(int i = 0; i < edges.count; i ++) {
        Edge *curr = edges[i];
        CLLocation *lowestPoint = curr.start; // A
        CLLocation *highestPoint = curr.end; // B
        // Note: latitude = y and longitude = x
        if(lowestPoint.coordinate.latitude > highestPoint.coordinate.latitude) {
            lowestPoint = curr.end;
            highestPoint = curr.start;
        }
        if([self isPointSameHeightAsEdge:curr point:point]) {
            point = [[CLLocation alloc] initWithLatitude:point.coordinate.latitude + DBL_EPSILON longitude:point.coordinate.longitude];
        }
        if(point.coordinate.latitude <= highestPoint.coordinate.latitude && point.coordinate.latitude >= lowestPoint.coordinate.latitude && point.coordinate.longitude <= MAX(lowestPoint.coordinate.longitude, highestPoint.coordinate.longitude)) {
            if(point.coordinate.longitude >= MIN(lowestPoint.coordinate.longitude, highestPoint.coordinate.longitude)) {
                double slopeOfEdge = 0.0;
                double slopeOfPoint = 0.0;
                @try {
                    slopeOfEdge = (highestPoint.coordinate.latitude - lowestPoint.coordinate.latitude) / (highestPoint.coordinate.longitude - lowestPoint.coordinate.longitude);
                } @catch (NSException *exception) {
                    slopeOfEdge = DBL_MAX;
                }
                @try {
                    slopeOfPoint = (point.coordinate.latitude - lowestPoint.coordinate.latitude) / (point.coordinate.longitude - lowestPoint.coordinate.longitude);
                } @catch (NSException *exception) {
                    slopeOfPoint = DBL_MAX;
                }
                if(slopeOfPoint >= slopeOfEdge) { // ray intersects with edge
                    inside = !inside;
                }
            }else { // ray intersects with edge
                inside = !inside;
            }
        }
    }
    return inside;
}

+ (BOOL)isPointSameHeightAsEdge:(Edge *)edge point:(CLLocation *)point {
    if(fabs(point.coordinate.latitude - edge.start.coordinate.latitude) < DBL_EPSILON ||
       fabs(point.coordinate.latitude - edge.end.coordinate.latitude) < DBL_EPSILON) {
        return YES;
    }
    return NO;
}

+ (NSMutableArray<Edge *> *)getPolygonEdges:(NSArray<CLLocation *> *)polygonCoordinates {
    NSMutableArray<Edge *> *result = [NSMutableArray<Edge *> new];
    for(int i = 0; i < polygonCoordinates.count; i ++) {
        Edge *edge = [[Edge alloc] init];
        edge.start = (CLLocation *)polygonCoordinates[i];
        edge.end = (CLLocation *)polygonCoordinates[(i + 1) % polygonCoordinates.count];
        [result addObject:edge];
    }
    return result;
}

+ (NSMutableArray<CLLocation *> *)getFourCornersOfGeohash:(GNGeoHash *)geohash {
    NSMutableArray<CLLocation *> *result = [NSMutableArray<CLLocation *> new];
    GNWGS84Point *upperLeftPoint =  [geohash.boundingBox getUpperLeft];
    GNWGS84Point *lowerRightPoint = [geohash.boundingBox getLowerRight];
    [result addObject:[[CLLocation alloc] initWithLatitude:upperLeftPoint.latitude longitude:upperLeftPoint.longitude]];
    [result addObject:[[CLLocation alloc] initWithLatitude:lowerRightPoint.latitude longitude:lowerRightPoint.longitude]];
    [result addObject:[[CLLocation alloc] initWithLatitude:lowerRightPoint.latitude longitude:upperLeftPoint.longitude]];
    [result addObject:[[CLLocation alloc] initWithLatitude:upperLeftPoint.latitude longitude:lowerRightPoint.longitude]];
    return result;
}

@end
