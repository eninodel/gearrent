//
//  CreateListingViewController.h
//  GearRent
//
//  Created by Edwin Delgado on 7/7/22.
//

#import <UIKit/UIKit.h>
#import <JTCalendar/JTCalendar.h>
#import "Listing.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CreateListingViewControllerDelegate <NSObject>

- (void)CRUDListing;

@end

@interface CreateListingViewController : UIViewController<JTCalendarDelegate>

@property (nonatomic, weak) id<CreateListingViewControllerDelegate> delegate;

@property (strong, nonatomic)Listing * _Nullable listing;

@property (weak, nonatomic) IBOutlet JTCalendarMenuView *calendarMenuView;
@property (weak, nonatomic) IBOutlet JTHorizontalCalendarView *calendarContentView;

@property (strong, nonatomic) JTCalendarManager *calendarManager;

@end

NS_ASSUME_NONNULL_END
