//
//  ListingTableViewCell.h
//  GearRent
//
//  Created by Edwin Delgado on 7/11/22.
//

#import <UIKit/UIKit.h>
#import "../Models/Item.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ListingTableViewCellDelegate <NSObject>

- (void) didEditListing: (Item *) listing;

- (void) didViewReservations: (Item *) listing;

@end

@interface ListingTableViewCell : UITableViewCell

@property (nonatomic, weak) id<ListingTableViewCellDelegate> delegate;

@property (strong, nonatomic) Item *listing;

@property (assign, nonatomic) Boolean findStatus;

- (void) initializeCell;

- (void) displayOptions;

@end

NS_ASSUME_NONNULL_END
