//
//  APIManager.h
//  GearRent
//
//  Created by Edwin Delgado on 7/20/22.
//

#import <Foundation/Foundation.h>
#import "Item.h"
#import "GNGeoHash.h"

NS_ASSUME_NONNULL_BEGIN

@interface APIManager : NSObject

void fetchListingsWithCoordinates(NSArray<CLLocation *> *coordinates, void(^)(NSArray<Item *> *, NSError *error));

@end

NS_ASSUME_NONNULL_END
