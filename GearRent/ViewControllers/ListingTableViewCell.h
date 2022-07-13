//
//  ListingTableViewCell.h
//  GearRent
//
//  Created by Edwin Delgado on 7/11/22.
//

#import <UIKit/UIKit.h>
#import "../Models/Item.h"

NS_ASSUME_NONNULL_BEGIN

@interface ListingTableViewCell : UITableViewCell

@property (strong, nonatomic) Item *listing;

@property (assign, nonatomic) Boolean findStatus;

- (void) initializeCell;

@end

NS_ASSUME_NONNULL_END
