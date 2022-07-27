//
//  Edge.h
//  GearRent
//
//  Created by Edwin Delgado on 7/20/22.
//

#import <Foundation/Foundation.h>
#import "CoreLocation/CoreLocation.h"

NS_ASSUME_NONNULL_BEGIN

@interface Edge : NSObject

@property (assign, nonatomic) CLLocation *start;
@property (assign, nonatomic) CLLocation *end;

@end

NS_ASSUME_NONNULL_END
