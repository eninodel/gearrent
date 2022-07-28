//
//  Filter.m
//  GearRent
//
//  Created by Edwin Delgado on 7/27/22.
//

#import "Filter.h"
#import "Parse/Parse.h"
#import <Foundation/Foundation.h>

@implementation Filter

@dynamic categoryId;
@dynamic userId;
@dynamic location;

+ (nonnull NSString *)parseClassName {
    return @"Filter";
}

@end
