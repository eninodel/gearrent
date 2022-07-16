//
//  BookingTableViewCell.m
//  GearRent
//
//  Created by Edwin Delgado on 7/15/22.
//

#import "BookingTableViewCell.h"
#import "../Models/Item.h"
#import "UIImageView+AFNetworking.h"

@interface BookingTableViewCell()

@property (strong, nonatomic) IBOutlet UIImageView *bookingImage;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *datesLeasedLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIButton *cancelReservationButton;

- (IBAction)didCancelReservation:(id)sender;

@end

@implementation BookingTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)initializeCell{
    NSString *datesLeasedString = @"Dates leased: ";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd-MM-yyyy";
    datesLeasedString = [datesLeasedString stringByAppendingString: [dateFormatter stringFromDate:self.reservation.dates.startDate]];
    datesLeasedString = [datesLeasedString stringByAppendingString:@" - "];
    datesLeasedString = [datesLeasedString stringByAppendingString: [dateFormatter stringFromDate:self.reservation.dates.endDate]];
    self.datesLeasedLabel.text = datesLeasedString;
    self.statusLabel.text = self.reservation.status;
    PFQuery *listingPhotoQuery = [PFQuery queryWithClassName:@"Listing"];
    [listingPhotoQuery whereKey:@"objectId" equalTo:self.reservation.itemId];
    [listingPhotoQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error == nil){
            Item *listing = (Item *) objects[0];
            self.titleLabel.text = listing.title;
            PFFileObject *image = (PFFileObject *) listing.images[0];
            NSURL *imageURL = [NSURL URLWithString: image.url];
            [self.imageView setImageWithURL:imageURL];
        } else{
            NSLog(@"END: Error in fetching photos");
        }
    }];
    if([self.reservation.status isEqualToString:@"ACCEPTED"] != YES){
        self.cancelReservationButton.hidden = YES;
    }
}

- (IBAction)didCancelReservation:(id)sender {
    self.reservation.status = @"CANCELLED";
    [self.reservation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(error == nil){
            NSLog(@"END: Successfully cancelled reservation");
        }else{
            NSLog(@"END: Error in canceling reservation");
        }
    }];
}

@end
