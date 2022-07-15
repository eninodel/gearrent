//
//  ReservationTableViewCell.m
//  GearRent
//
//  Created by Edwin Delgado on 7/15/22.
//

#import "ReservationTableViewCell.h"

@interface ReservationTableViewCell()

@property (strong, nonatomic) IBOutlet UIImageView *reservationImage;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *datesReservedLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIButton *cancelReservationButton;

- (IBAction)didCancelReservation:(id)sender;

@end

@implementation ReservationTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initializeCell{
}

- (IBAction)didCancelReservation:(id)sender {
}
@end
