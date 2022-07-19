//
//  ListingTableViewCell.m
//  GearRent
//
//  Created by Edwin Delgado on 7/11/22.
//

#import "ListingTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "TimeInterval.h"
#import "Reservation.h"
#import "Item.h"
#import "CreateListingViewController.h"

@interface ListingTableViewCell ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UILabel *priceLabel;
@property (strong, nonatomic) IBOutlet UIImageView *listingImageView;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIView *cellOptionsView;
@property (strong, nonatomic) IBOutlet UIButton *editListingButton;
@property (strong, nonatomic) IBOutlet UIButton *viewReservationsButton;

- (IBAction)didViewReservations:(id)sender;
- (IBAction)didEditListing:(id)sender;

@end

@implementation ListingTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)displayOptions {
    self.cellOptionsView.hidden = !self.cellOptionsView.hidden;
    [self bringSubviewToFront:self.cellOptionsView];
}

- (void)initializeCell {
    self.cellOptionsView.hidden = YES;
    self.titleLabel.text = self.listing.title;
    self.locationLabel.text = self.listing.city;
    NSString *priceString = @"$";
    priceString = [priceString stringByAppendingString:[[NSNumber numberWithFloat:self.listing.price] stringValue]];
    priceString = [priceString stringByAppendingString:@" / day"];
    self.priceLabel.text = priceString;
    if(self.listing.images.count > 0){
        PFFileObject *image = (PFFileObject *) self.listing.images[0];
        NSURL *imageURL = [NSURL URLWithString: image.url];
        [self.listingImageView setImageWithURL: imageURL];
    }
    self.statusLabel.hidden = YES;
    if(self.findStatus == YES){
        [self statusForCell];
    }
}

- (void)statusForCell {
    NSString *__block status = @"Unavailable Today";
    NSDate *today = [self dateWithHour:0 minute:0 second:0];
    PFQuery *query = [PFQuery queryWithClassName:@"Reservation"];
    [query includeKey:@"dates"];
    [query whereKey:@"itemId" equalTo:[self.listing objectId] ];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error == nil){
            // check if available
            if(self.listing.isAlwaysAvailable == YES){
                status = @"Available to Rent today";
            }
            for(int i = 0; i < self.listing.availabilities.count; i++){
                TimeInterval *interval = (TimeInterval *) self.listing.availabilities[i];
                NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate: interval.startDate endDate: interval.endDate];
                if([dateInterval containsDate:today]){
                    status =  @"Available to Rent today";
                }
            }
            // check if reserved
            for(int i = 0; i < objects.count; i++){
                Reservation *reservation = (Reservation *) objects[i];
                NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:reservation.dates.startDate endDate:reservation.dates.endDate];
                if([dateInterval containsDate:today]){
                    NSString *reservationString = @"Reserved: ";
                    reservationString = [reservationString stringByAppendingString: reservation.status];
                    status =  reservationString;
                }
            }
            self.statusLabel.hidden = NO;
            self.statusLabel.text = status;
            [self.statusLabel sizeToFit];
        }else{
            NSLog(@"END: Error fetching reservation dates");
        }
    }];
}

-(NSDate *)dateWithHour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second {
   NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components: NSCalendarUnitYear|
                                    NSCalendarUnitMonth|
                                    NSCalendarUnitDay
                                               fromDate:[NSDate date]];
    [components setHour:hour];
    [components setMinute:minute];
    [components setSecond:second];
    NSDate *newDate = [calendar dateFromComponents:components];
    return newDate;
}

- (IBAction)didEditListing:(id)sender {
    [self.delegate didEditListing: self.listing];
}

- (IBAction)didViewReservations:(id)sender {
    [self.delegate didViewReservations: self.listing];
}

@end
