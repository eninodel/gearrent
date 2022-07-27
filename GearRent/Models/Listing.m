//
//  Listing.m
//  GearRent
//
//  Created by Edwin Delgado on 7/8/22.
//

#import "Listing.h"
#import "Parse/Parse.h"
#import <Foundation/Foundation.h>

@implementation Listing

@dynamic title;
@dynamic itemDescription;
@dynamic price;
@dynamic images;
@dynamic videoURL;
@dynamic ownerId;
@dynamic tags;
@dynamic geoPoint;
@dynamic location;
@dynamic reservations;
@dynamic availabilities;
@dynamic isAlwaysAvailable;
@dynamic geohash;
@dynamic dynamicPrice;
@dynamic minPrice;
@dynamic categoryId;

+ (nonnull NSString *)parseClassName {
    return @"Listing";
}

@end
