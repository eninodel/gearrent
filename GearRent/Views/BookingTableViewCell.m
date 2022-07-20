//
//  BookingTableViewCell.m
//  GearRent
//
//  Created by Edwin Delgado on 7/15/22.
//

#import "BookingTableViewCell.h"
#import "Item.h"
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

- (void)initializeCell {
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
    __weak typeof(self) weakSelf = self;
    [listingPhotoQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf){
            if(objects.count > 0 && [objects[0] isKindOfClass:[Item class]]){
                Item *listing = (Item *)objects[0];
                strongSelf.titleLabel.text = listing.title;
                PFFileObject *image = (PFFileObject *) listing.images[0];
                NSURL *imageURL = [NSURL URLWithString: image.url];
                [strongSelf.imageView setImageWithURL:imageURL];
            } else{
                UIImage *image = [UIImage imageNamed:@"DefaultListingImage"];
                [strongSelf.imageView setImage:image];
            }
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
