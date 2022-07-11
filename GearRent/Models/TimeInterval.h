//
//  TimeInterval.h
//  GearRent
//
//  Created by Edwin Delgado on 7/8/22.
//

#import <Foundation/Foundation.h>
#import "Parse/Parse.h"

NS_ASSUME_NONNULL_BEGIN

@interface TimeInterval : PFObject<PFSubclassing>
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@end

NS_ASSUME_NONNULL_END
