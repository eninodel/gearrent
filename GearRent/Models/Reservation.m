//
//  Reservation.m
//  GearRent
//
//  Created by Edwin Delgado on 7/8/22.
//

#import "Reservation.h"
#import "Parse/Parse.h"

@implementation Reservation
@dynamic itemId;
@dynamic leaserId;
@dynamic leaseeId;
@dynamic dates;
@dynamic status;

+ (nonnull NSString *)parseClassName {
    return @"Reservation";
}

@end
