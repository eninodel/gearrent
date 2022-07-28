//
//  FiltersTableViewCell.h
//  GearRent
//
//  Created by Edwin Delgado on 7/28/22.
//

#import <UIKit/UIKit.h>
#import "Category.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FiltersTableViewCellDelegate <NSObject>

- (void)didSelectCategory: (NSString *) categoryId;

- (void)didUnselectCategory: (NSString *)categoryId;

@end

@interface FiltersTableViewCell : UITableViewCell

@property (nonatomic, weak) id<FiltersTableViewCellDelegate> delegate;

@property (nonatomic, strong) Category *category;

- (void)initializeCell;

@end

NS_ASSUME_NONNULL_END
