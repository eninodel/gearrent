//
//  DetailsViewController.h
//  GearRent
//
//  Created by Edwin Delgado on 7/12/22.
//

#import <UIKit/UIKit.h>
#import "Item.h"
#import <JTCalendar/JTCalendar.h>

NS_ASSUME_NONNULL_BEGIN

@interface DetailsViewController : UIViewController

@property (strong, nonatomic) Item *listing;

@property (weak, nonatomic) IBOutlet JTCalendarMenuView *calendarMenuView;
@property (weak, nonatomic) IBOutlet JTHorizontalCalendarView *calendarContentView;

@property (strong, nonatomic) JTCalendarManager *calendarManager;
@end

NS_ASSUME_NONNULL_END
