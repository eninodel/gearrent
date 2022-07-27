//
//  Category.h
//  GearRent
//
//  Created by Edwin Delgado on 7/27/22.
//

#import <Foundation/Foundation.h>
#import "Parse/Parse.h"

NS_ASSUME_NONNULL_BEGIN

@interface Category : PFObject

@property(nonatomic, strong) NSString *title;

@end

NS_ASSUME_NONNULL_END
