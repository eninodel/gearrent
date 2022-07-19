//
//  ReservationTableViewCell.h
//  GearRent
//
//  Created by Edwin Delgado on 7/14/22.
//

#import <UIKit/UIKit.h>
#import "Reservation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReservationTableViewCell : UITableViewCell

@property (strong, nonatomic) Reservation *reservation;

- (void)initializeCell;

@end

NS_ASSUME_NONNULL_END
