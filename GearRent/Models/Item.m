//
//  Listing.m
//  GearRent
//
//  Created by Edwin Delgado on 7/8/22.
//

#import "Item.h"
#import "Parse/Parse.h"
#import <Foundation/Foundation.h>

@implementation Item

@dynamic title;
@dynamic itemDescription;
@dynamic price;
@dynamic images;
@dynamic videoURL;
@dynamic ownerId;
@dynamic tags;
@dynamic geoPoint;
@dynamic city;
@dynamic reservations;
@dynamic availabilities;
@dynamic isAlwaysAvailable;


+ (nonnull NSString *)parseClassName {
    return @"Listing";
}



@end
