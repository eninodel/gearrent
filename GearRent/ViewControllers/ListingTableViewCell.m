//
//  ListingTableViewCell.m
//  GearRent
//
//  Created by Edwin Delgado on 7/11/22.
//

#import "ListingTableViewCell.h"
#import "UIImageView+AFNetworking.h"

@interface ListingTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *listingImageView;

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
}


@end
