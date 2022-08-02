//
//  FiltersTableViewCell.m
//  GearRent
//
//  Created by Edwin Delgado on 7/28/22.
//

#import "FiltersTableViewCell.h"

@interface FiltersTableViewCell()

@property (strong, nonatomic) IBOutlet UILabel *categoryLabel;
@property (strong, nonatomic) IBOutlet UISwitch *selectedSwitch;

- (IBAction)didSelect:(id)sender;


@end

@implementation FiltersTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initializeCell {
    self.categoryLabel.text = self.category[@"title"];
}

- (IBAction)didSelect:(id)sender {
    if([self.selectedSwitch isOn]) {
        [self.delegate didSelectCategory:[self.category objectId]];
    } else {
        [self.delegate didUnselectCategory:[self.category objectId]];
    }
}
@end
