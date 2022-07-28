//
//  Address.m
//  GearRent
//
//  Created by Edwin Delgado on 7/28/22.
//

#import "Address.h"

@implementation Address

- (NSString *_Nullable)getSmallestEntity
{
    return self.town ?: self.city ?: self.county;
}

-(instancetype) initWithDictionary:(NSDictionary *_Nullable)dictionary
{
    if(self = [super init]) {
        self.town = dictionary[@"town"];
        self.city = dictionary[@"city"];
        self.county = dictionary[@"county"];
    }

    return self;
}

@end
