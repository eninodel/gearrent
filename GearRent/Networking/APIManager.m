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
#import "Listing.h"
#import "Filter.h"
#import "Reservation.h"
#import "TimeInterval.h"
#import "Foundation/Foundation.h"
#import "Category.h"
#import "Address.h"

static int const kMaxGeoHashPrecision = 7;

@implementation APIManager{
    NSURLSessionDataTask *_Nullable fetchNearestCityTask;
    NSURLSessionDataTask *_Nullable isTodayAHolidayTask;
}

extern void fetchListingsWithCoordinates(NSArray<CLLocation *> *polygonCoordinates, void(^completion)(NSArray<Listing *> *, NSError *)){
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
          NSMutableArray<Listing *> *allListings = [NSMutableArray<Listing *> new];
          NSArray<NSArray<Listing *> *> *results = listings;
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

- (void)fetchNearestCity:(CLLocation *)location completion: (void(^_Nonnull)(NSString *, NSError *)) completion {
        NSDictionary *headers = @{ @"X-RapidAPI-Key": @"4ee4de8731msh81f644e471716bbp14ba33jsnae748db48874",
                               @"X-RapidAPI-Host": @"forward-reverse-geocoding.p.rapidapi.com" };
        NSString *requestURL = [NSString stringWithFormat:@"https://forward-reverse-geocoding.p.rapidapi.com/v1/reverse?lat=%f&lon=%f&accept-language=en&polygon_threshold=0.0&zoom=10", location.coordinate.latitude, location.coordinate.longitude];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: requestURL]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
        [request setHTTPMethod:@"GET"];
        [request setAllHTTPHeaderFields:headers];

        NSURLSession *session = [NSURLSession sharedSession];
        __block BOOL done = NO;
         fetchNearestCityTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    done = YES;
                                                    if (error) {
                                                        completion(nil, error);
                                                    } else {
                                                        NSString *strISOLatin = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
                                                        NSData *dataUTF8 = [strISOLatin dataUsingEncoding:NSUTF8StringEncoding];
                                                        id dict = [NSJSONSerialization JSONObjectWithData:dataUTF8 options:0 error:&error];
                                                        if (dict != nil) {
                                                            Address *address = [[Address alloc] initWithDictionary:dict[@"address"]];
                                                            completion([address getSmallestEntity], nil);
                                                        } else {
                                                            NSLog(@"Error: %@", error);
                                                            completion(nil, error);
                                                        }
                                                    }
             self->fetchNearestCityTask = nil;
         }];
        [self->fetchNearestCityTask resume];
}

- (void)isTodayAHoliday:(void(^_Nonnull)(BOOL, NSError *)) completion{
    NSDictionary *headers = @{ @"X-RapidAPI-Key": @"4ee4de8731msh81f644e471716bbp14ba33jsnae748db48874",
                           @"X-RapidAPI-Host": @"public-holiday.p.rapidapi.com" };
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: @"https://public-holiday.p.rapidapi.com/2022/US"]
                                                       cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                   timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    [request setAllHTTPHeaderFields:headers];

    NSURLSession *session = [NSURLSession sharedSession];
    __block BOOL done = NO;
    isTodayAHolidayTask = [session dataTaskWithRequest:request
                                           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                               done = YES;
                                               if (error) {
                                                   completion(nil, error);
                                               } else {
                                                   NSDate *today = [APIManager dateWithHour:0 minute:0 second:0];
                                                   NSString *strISOLatin = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
                                                   NSData *dataUTF8 = [strISOLatin dataUsingEncoding:NSUTF8StringEncoding];
                                                   NSArray *holidays = [NSJSONSerialization JSONObjectWithData:dataUTF8 options:0 error:&error];
                                                   if (holidays != nil) {
                                                       for(int i = 0; i < holidays.count; i ++){
                                                           NSDictionary *holiday = holidays[i];
                                                           NSString *dateString = [holiday valueForKey:@"date"];
                                                           NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                                           [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                                                           NSDate *date = [dateFormatter dateFromString:dateString];
                                                           if([date isEqualToDate:today]){
                                                               completion(YES, nil);
                                                           }
                                                       }
                                                       completion(NO, nil);
                                                   } else {
                                                       NSLog(@"Error: %@", error);
                                                       completion(nil, error);
                                                   }
                                               }
        self->isTodayAHolidayTask = nil;
    }];
   [self->isTodayAHolidayTask resume];
}

extern void fetchDynamicPrice(Listing *listing, void(^completion)(CGFloat, NSError *)) {
    NSInteger lookback = 24;
    __block NSInteger numberOfSearchesForCategoryInPast24Hours = 0;
    __block NSInteger numberOfReservationsSentInPast24Hours = 0;
    __block CGFloat supplyFactor = 0.0;
    __block BOOL holiday = NO;
    dispatch_group_t serviceGroup = dispatch_group_create();
    dispatch_group_enter(serviceGroup);
    [APIManager searchesInPastHours:lookback categoryId:listing.categoryId location:listing.location completion:^(NSInteger result, NSError *error) {
        if(error){
            NSLog(@"%@", error);
        } else{
            numberOfSearchesForCategoryInPast24Hours = result;
        }
        dispatch_group_leave(serviceGroup);
    }];
    dispatch_group_enter(serviceGroup);
    [APIManager reservationsInPastHours:[listing objectId] hours:lookback completion:^(NSInteger result, NSError *error) {
        if(error){
            NSLog(@"%@", error);
        } else{
            numberOfReservationsSentInPast24Hours = result;
        }
        dispatch_group_leave(serviceGroup);
    }];
    dispatch_group_enter(serviceGroup);
    [APIManager supplyAvailableForListing:listing completion:^(CGFloat result, NSError *error) {
        supplyFactor = result;
        dispatch_group_leave(serviceGroup);
    }];
    dispatch_group_enter(serviceGroup);
    [[APIManager alloc] isTodayAHoliday:^(BOOL isTodayAHoliday, NSError *error) {
        if(error == nil){
            holiday = isTodayAHoliday;
        }
        dispatch_group_leave(serviceGroup);
    }];
    dispatch_group_notify(serviceGroup, dispatch_get_main_queue(), ^{
        NSDate *today = [APIManager dateWithHour:0 minute:0 second:0];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        CGFloat minPrice = listing.minPrice;
        CGFloat weekendSurcharge = [calendar isDateInWeekend:today] ? 0.05 : 0.0;
        CGFloat holidaySurcharge = holiday ? 0.05 : 0.0;
        CGFloat searchesSurcharge = 0.15 * ((CGFloat)numberOfSearchesForCategoryInPast24Hours / (1 + numberOfSearchesForCategoryInPast24Hours));
        CGFloat numberOfReservationsSurcharge = 0.5 *((CGFloat)numberOfReservationsSentInPast24Hours / (1 + numberOfReservationsSentInPast24Hours));
        CGFloat supplySurcharge = 0.25 * supplyFactor;
        CGFloat dynamicPriceTotal = minPrice * (1 + weekendSurcharge + holidaySurcharge + searchesSurcharge + numberOfReservationsSurcharge + supplySurcharge);
        completion(dynamicPriceTotal, nil);
    });
}

+ (BOOL)isListingInitiallyAvailableToday:(Listing *)listing {
    if(listing.isAlwaysAvailable){
        return YES;
    }
    NSMutableArray<TimeInterval *> *availabilities = listing.availabilities;
    NSDate *today = [APIManager dateWithHour:0 minute:0 second:0];
    for(int i = 0; i < availabilities.count; i++ ){
        TimeInterval *curr = availabilities[i];
        NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate: curr.startDate endDate: curr.endDate];
        if([dateInterval containsDate:today]){
            return YES;
        }
    }
    return NO;
}

+ (void)isListingReservedToday:(Listing *)listing completion:(void (^_Nonnull)(BOOL, NSError *))completion {
    NSMutableArray<Reservation *> *reservations = listing.reservations;
    NSDate *today = [APIManager dateWithHour:0 minute:0 second:0];
    for(int i = 0; i < reservations.count; i++){
        Reservation *curr = reservations[i];
        PFQuery *reservationQuery = [PFQuery queryWithClassName:@"Reservation"];
        [reservationQuery whereKey:@"itemId" equalTo: [curr objectId]];
        [reservationQuery includeKey:@"dates"];
        [reservationQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if(error == nil){
                for(int i = 0; i < objects.count; i++){
                    Reservation *reservation = (Reservation *) objects[i];
                    NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:reservation.dates.startDate endDate:reservation.dates.endDate];
                    if([dateInterval containsDate:today]){
                        completion(YES, nil);
                        return;
                    }
                }
            }else{
                NSLog(@"END: Error in querying reservations");
            }
        }];
    }
    completion(NO, nil);
}

+ (void)supplyAvailableForListing:(Listing *)listing completion:(void (^_Nonnull)(CGFloat, NSError *))completion{
    __block NSInteger totalListings = 0;
    __block NSInteger confirmedListings = 0;
    dispatch_group_t reservationGroup = dispatch_group_create();
    dispatch_group_notify(reservationGroup, dispatch_get_main_queue(), ^{
        CGFloat result = confirmedListings / totalListings;
        completion(result, nil);
    });
    PFQuery *query = [PFQuery queryWithClassName:@"Listing"];
    [query whereKey:@"categoryId" equalTo:listing.categoryId];
    [query whereKey:@"location" equalTo:listing.location];
    [query includeKey:@"availabilities"];
    [query includeKey:@"reservations"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error){
            NSLog(@"%@", error);
        } else{
            NSArray<Listing *> *similarListings = (NSArray<Listing *> *) objects;
            for(Listing *listing in similarListings){
                if([APIManager isListingInitiallyAvailableToday:listing]){ //check if listing is reserved today
                    totalListings ++;
                }
                dispatch_group_enter(reservationGroup);
                [APIManager isListingReservedToday:listing completion:^(BOOL isReserved, NSError *error) {
                    if(error){
                        NSLog(@"%@", error);
                    } else if(isReserved){
                        confirmedListings ++;
                    }
                    dispatch_group_leave(reservationGroup);
                }];
            }
        }
    }];
}

+ (void)reservationsInPastHours:(NSString *)listingId hours:(NSInteger)hours completion:(void (^_Nonnull)(NSInteger, NSError *))completion {
    PFQuery *query = [PFQuery queryWithClassName:@"Reservation"];
    [query whereKey:@"itemId" equalTo:listingId];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error){
            NSLog(@"END: Failed getting reservations");
            completion(-1, error);
        } else{
            NSLog(@"END: Successfully fetched reservations");
            NSArray<Reservation *> *reservations = (NSArray<Reservation *> *)objects;
            CGFloat threshold = (3600.0 * hours);
            NSInteger result = 0;
            for(Reservation *reservation in reservations){
                NSTimeInterval timeInterval = [[NSDate new] timeIntervalSinceDate:reservation.createdAt];
                if(timeInterval <= threshold && timeInterval >= 0){ // within past x hours
                    result ++;
                }
            }
            completion(result, nil);
        }
    }];
}

+ (void)searchesInPastHours:(NSInteger )hours categoryId:(NSString *)categoryId location:(NSString *)location completion:(void (^_Nonnull)(NSInteger, NSError *))completion {
    PFQuery *query = [PFQuery queryWithClassName:@"Filter"];
    [query whereKey:@"categoryId" equalTo:categoryId];
    [query whereKey:@"location" equalTo:location];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error){
            NSLog(@"END: Failed getting filters");
            completion(-1, error);
        } else{
            NSLog(@"END: Successfully fetched filters");
            NSArray<Filter *> *filters = (NSArray<Filter *> *)objects;
            CGFloat threshold = (3600.0 * hours);
            NSInteger result = 0;
            for(Filter *filter in filters){
                NSTimeInterval timeInterval = [[NSDate new] timeIntervalSinceDate:filter.createdAt];
                if(timeInterval <= threshold && timeInterval >= 0){ // within past x hours
                    result ++;
                }
            }
            completion(result, nil);
        }
    }];
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

extern void fetchAllCategories(void(^completion)(NSArray<Category *> *, NSError *)){
    PFQuery *query = [PFQuery queryWithClassName:@"Category"];
    [query whereKey:@"title" notEqualTo:@""];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else{
            completion((NSArray<Category *> *)objects, nil);
        }
    }];
}

+(NSDate *)dateWithHour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second {
   NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components: NSCalendarUnitYear|
                                    NSCalendarUnitMonth|
                                    NSCalendarUnitDay
                                               fromDate:[NSDate date]];
    [components setHour:hour];
    [components setMinute:minute];
    [components setSecond:second];
    NSDate *newDate = [calendar dateFromComponents:components];
    return newDate;
}

@end
