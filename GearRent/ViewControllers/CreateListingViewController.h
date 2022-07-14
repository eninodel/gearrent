//
//  CreateListingViewController.h
//  GearRent
//
//  Created by Edwin Delgado on 7/7/22.
//

#import <UIKit/UIKit.h>
#import <JTCalendar/JTCalendar.h>
#import "../Models/Item.h"

NS_ASSUME_NONNULL_BEGIN
@interface CreateListingViewController : UIViewController<JTCalendarDelegate>

@property (strong, nonatomic)Item * _Nullable listing;

@property (weak, nonatomic) IBOutlet JTCalendarMenuView *calendarMenuView;
@property (weak, nonatomic) IBOutlet JTHorizontalCalendarView *calendarContentView;

@property (strong, nonatomic) JTCalendarManager *calendarManager;
@end

NS_ASSUME_NONNULL_END
