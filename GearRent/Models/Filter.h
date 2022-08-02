//
//  Filter.h
//  GearRent
//
//  Created by Edwin Delgado on 7/27/22.
//

#import <Foundation/Foundation.h>
#import "Parse/Parse.h"


NS_ASSUME_NONNULL_BEGIN

@interface Filter : PFObject<PFSubclassing>

@property(nonatomic, strong) NSString *categoryId;
@property(nonatomic, strong) NSString *userId;
@property(nonatomic, strong) NSString *location;

@end

NS_ASSUME_NONNULL_END
