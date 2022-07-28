//
//  Address.h
//  GearRent
//
//  Created by Edwin Delgado on 7/28/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Address : NSObject

@property (nonatomic, nullable, strong) NSString *town;
@property (nonatomic, nullable, strong) NSString *city;
@property (nonatomic, nullable, strong) NSString *county;

- (NSString *_Nullable)getSmallestEntity;
-(instancetype) initWithDictionary:(NSDictionary *_Nullable)dictionary;

@end

NS_ASSUME_NONNULL_END
