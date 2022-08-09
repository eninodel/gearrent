//
//  BookingTableViewCell.m
//  GearRent
//
//  Created by Edwin Delgado on 7/15/22.
//

#import "BookingTableViewCell.h"
#import "Listing.h"
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
    NSString *datesLeasedString = @"";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd-MM-yyyy";
    datesLeasedString = [datesLeasedString stringByAppendingString: [dateFormatter stringFromDate:self.reservation.dates.startDate]];
    datesLeasedString = [datesLeasedString stringByAppendingString:@" - "];
    datesLeasedString = [datesLeasedString stringByAppendingString: [dateFormatter stringFromDate:self.reservation.dates.endDate]];
    self.datesLeasedLabel.text = [NSString stringWithFormat:@"%@\r%@", @"Dates leased:", datesLeasedString];
    self.statusLabel.text = self.reservation.status;
    PFQuery *listingPhotoQuery = [PFQuery queryWithClassName:@"Listing"];
    [listingPhotoQuery whereKey:@"objectId" equalTo:self.reservation.itemId];
    __weak typeof(self) weakSelf = self;
    [listingPhotoQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf) {
            if(objects.count > 0 && [objects[0] isKindOfClass:[Listing class]]){
                Listing *listing = (Listing *)objects[0];
                strongSelf.titleLabel.text = listing.title;
                PFFileObject *image = (PFFileObject *) listing.images[0];
                NSURL *imageURL = [NSURL URLWithString: image.url];
                NSURLRequest *request = [[NSURLRequest alloc] initWithURL:imageURL];
                [strongSelf.bookingImage setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"DefaultListingImage"] success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                    NSLog(@"END: Successfully added image in booking tableview cell");
                    [strongSelf.bookingImage setImage:image];
                } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                    NSLog(@"%@", error);
                }];
            } else {
                UIImage *image = [UIImage imageNamed:@"DefaultListingImage"];
                [strongSelf.imageView setImage:image];
            }
        } else {
            NSLog(@"END: Error in fetching photos");
        }
    }];
    if([self.reservation.status isEqualToString:@"CONFIRMED"] != YES){
        self.cancelReservationButton.hidden = YES;
    }
}

- (IBAction)didCancelReservation:(id)sender {
    self.reservation.status = @"DECLINED";
    __weak typeof(self) weakSelf = self;
    [self.cancelReservationButton setHidden:YES];
    [self.reservation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil) {
            if(strongSelf) {
                [strongSelf initializeCell];
            }
            NSLog(@"END: Successfully cancelled reservation");
        }else {
            NSLog(@"END: Error in canceling reservation");
            [self.cancelReservationButton setHidden:NO];
        }
    }];
}

@end
