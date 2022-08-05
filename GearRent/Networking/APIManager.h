//
//  APIManager.h
//  GearRent
//
//  Created by Edwin Delgado on 7/20/22.
//

#import <Foundation/Foundation.h>
#import "Listing.h"
#import "GNGeoHash.h"
#import "Category.h"

NS_ASSUME_NONNULL_BEGIN

extern void fetchAllCategories(void(^completion)(NSArray<Category *> *, NSError *));
extern void fetchDynamicPrice(Listing *listing, NSMutableArray<NSMutableArray<NSNumber *> *> *dateRanges, void(^completion)(NSDictionary<NSNumber *, NSNumber *> *, NSError *));
extern void fetchListingsWithCoordinates(NSArray<CLLocation *> *coordinates, void(^completion)(NSArray<Listing *> *, NSError *error));

@interface APIManager : NSObject

+ (void)fetchNearestCity:(CLLocation *)location completion: (void(^_Nonnull)(NSString *, NSError *)) completion;

@end

NS_ASSUME_NONNULL_END
