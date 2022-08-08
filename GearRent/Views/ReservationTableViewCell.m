//
//  ReservationTableViewCell.m
//  GearRent
//
//  Created by Edwin Delgado on 7/14/22.
//

#import "ReservationTableViewCell.h"

@interface ReservationTableViewCell()
@property (strong, nonatomic) IBOutlet UILabel *leaseeLabel;
@property (strong, nonatomic) IBOutlet UILabel *datesLeasedLabel;
@property (strong, nonatomic) IBOutlet UILabel *currentStatusLabel;
@property (strong, nonatomic) IBOutlet UIButton *declineButton;
@property (strong, nonatomic) IBOutlet UIButton *acceptButton;

- (IBAction)didAccept:(id)sender;
- (IBAction)didDecline:(id)sender;
@end

@implementation ReservationTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initializeCell {
    self.currentStatusLabel.text = self.reservation.status;
    if(![self.reservation.status isEqualToString:@"UNCONFIRMED"]) {
        [self.declineButton setHidden:YES];
        [self.acceptButton setHidden:YES];
    }
    NSString *datesLeasedString = @"Dates leased: ";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd-MM-yyyy";
    NSLog(@"%@", self.reservation.dates.startDate);
    datesLeasedString = [datesLeasedString stringByAppendingString: [dateFormatter stringFromDate:self.reservation.dates.startDate]];
    datesLeasedString = [datesLeasedString stringByAppendingString:@" - "];
    datesLeasedString = [datesLeasedString stringByAppendingString: [dateFormatter stringFromDate:self.reservation.dates.endDate]];
    self.datesLeasedLabel.text = datesLeasedString;
    PFQuery *query = [PFUser query];
    [query whereKey:@"objectId" equalTo:self.reservation.leaseeId];
    [query includeKey:@"name"];
    __weak typeof(self) weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf){
            PFUser *leasee = objects[0];
            strongSelf.leaseeLabel.text = leasee[@"name"];
        }else{
            NSLog(@"END: Error in getting leasee");
        }
    }];
}

- (IBAction)didDecline:(id)sender {
    self.reservation.status = @"DECLINED";
    self.currentStatusLabel.text = self.reservation.status;
    [self.declineButton setHidden:YES];
    [self.acceptButton setHidden:YES];
    [self.reservation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(error == nil) {
            NSLog(@"END: successfullly declined reservation");
        } else {
            NSLog(@"END: error in declining reservation");
        }
    }];
}

- (IBAction)didAccept:(id)sender {
    // TODO: After reservation is accepted, don't allow other reservations on same dates to be accepted as well
    self.reservation.status = @"CONFIRMED";
    self.currentStatusLabel.text = self.reservation.status;
    [self.declineButton setHidden:YES];
    [self.acceptButton setHidden:YES];
    [self.reservation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(error == nil) {
            NSLog(@"END: successfullly accepted reservation");
        } else {
            NSLog(@"END: error in accepting reservation");
        }
    }];
}

@end
