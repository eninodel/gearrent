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

@interface APIManager : NSObject

void fetchListingsWithCoordinates(NSArray<CLLocation *> *coordinates, void(^completion)(NSArray<Listing *> *, NSError *error));
- (void)fetchNearestCity:(CLLocation *)location completion: (void(^_Nonnull)(NSString *, NSError *)) completion;
void fetchAllCategories(void(^completion)(NSArray<Category *> *, NSError *));

@end

NS_ASSUME_NONNULL_END
