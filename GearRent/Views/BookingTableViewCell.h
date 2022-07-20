//
//  BookingTableViewCell.h
//  GearRent
//
//  Created by Edwin Delgado on 7/15/22.
//

#import <UIKit/UIKit.h>
#import "Reservation.h"

NS_ASSUME_NONNULL_BEGIN

@interface BookingTableViewCell : UITableViewCell

@property (strong, nonatomic)Reservation *reservation;

- (void) initializeCell;

@end

NS_ASSUME_NONNULL_END
