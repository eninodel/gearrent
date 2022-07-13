//
//  ListingTableViewCell.m
//  GearRent
//
//  Created by Edwin Delgado on 7/11/22.
//

#import "ListingTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "../Models/TimeInterval.h"
#import "../Models/Reservation.h"
#import "../Models/Item.h"

@interface ListingTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *listingImageView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation ListingTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void) initializeCell{
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

- (void) statusForCell{
    NSString *__block status = @"Unavailable Today";
    NSDate *today = [NSDate date];
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


@end
