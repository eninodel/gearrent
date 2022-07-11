//
//  Listing.h
//  GearRent
//
//  Created by Edwin Delgado on 7/8/22.
//

#import <Foundation/Foundation.h>
#import "Parse/Parse.h"

NS_ASSUME_NONNULL_BEGIN

@interface Item : PFObject<PFSubclassing>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *itemDescription;
@property (nonatomic) float price;
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) NSString *videoURL;
@property (nonatomic, strong) NSString *ownerId;
@property (nonatomic, strong) NSMutableArray *tags;
@property (nonatomic, strong) PFGeoPoint *geoPoint;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSMutableArray *reservations;
@property (nonatomic, strong) NSMutableArray *availabilities;
@property (nonatomic) Boolean isAlwaysAvailable;

@end

NS_ASSUME_NONNULL_END
