//
//  Reservation.h
//  GearRent
//
//  Created by Edwin Delgado on 7/8/22.
//

#import <Foundation/Foundation.h>
#import "Parse/Parse.h"
#import "TimeInterval.h"

NS_ASSUME_NONNULL_BEGIN

@interface Reservation : PFObject<PFSubclassing>
@property (nonatomic, strong) NSString *itemId;
@property (nonatomic, strong) NSString *leaserId;
@property (nonatomic, strong) NSString *leaseeId;
@property (nonatomic, strong) TimeInterval *dates;
@property (nonatomic, strong) NSString *status;

@end

NS_ASSUME_NONNULL_END
