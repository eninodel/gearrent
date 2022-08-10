//
//  DetailsViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/12/22.
//

#import "DetailsViewController.h"
#import "MapKit/MapKit.h"
#import "CoreLocation/CoreLocation.h"
#import "ImageCarouselCollectionViewCell.h"
#import "Parse/Parse.h"
#import <JTCalendar/JTCalendar.h>
#import "UIImageView+AFNetworking.h"
#import "TimeInterval.h"
#import "Listing.h"
#import "Reservation.h"
#import "APIManager.h"

@interface DetailsViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, JTCalendarDelegate, MKMapViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView *carouselCollectionView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UILabel *ownerLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel *priceLabel;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIButton *reserveNowButton;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *reservations;
@property (strong, nonatomic) NSMutableArray *datesSelected;
@property (strong, nonatomic) NSMutableArray *datesReserved;
@property (strong, nonatomic) NSMutableArray *datesAvailable;
@property (strong, nonatomic) NSMutableSet<NSDate *> *datesForDynamicPricingSet;
@property (strong, nonatomic) NSMutableArray<NSMutableArray<NSNumber *> *> *dateRanges;
@property (strong, nonatomic) NSMutableDictionary<NSDate *, NSNumber *> *datesToPrices;
@property (strong, nonatomic) IBOutlet UILabel *categoryLabel;

- (IBAction)didReserveNow:(id)sender;
- (IBAction)didTapBack:(id)sender;

@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.datesForDynamicPricingSet = [NSMutableSet<NSDate *> new];
    self.dateRanges = [NSMutableArray<NSMutableArray<NSNumber *> *> new];
    self.datesToPrices = [NSMutableDictionary<NSDate *, NSNumber *> new];
    self.carouselCollectionView.delegate = self;
    self.carouselCollectionView.dataSource = self;
    self.titleLabel.text = self.listing.title;
    self.titleLabel.minimumScaleFactor = 0.5;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.locationLabel.text = self.listing.location;
    self.descriptionLabel.text = self.listing.itemDescription;
    self.categoryLabel.text = self.listing[@"category"][@"title"];
    PFQuery *query = [PFUser query];
    [query whereKey:@"objectId" equalTo: self.listing.ownerId];
    __weak typeof(self) weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf){
            PFUser *owner = (PFUser *) objects[0];
            strongSelf.ownerLabel.text = owner[@"name"];
        } else{
            NSLog(@"END: Error in getting user in DetailsViewController");
        }
    }];
    if(self.listing.dynamicPrice) {
        [self.priceLabel setHidden:YES];
    } else {
        NSString *priceString = @"$";
        priceString = [priceString stringByAppendingString:[[NSNumber numberWithFloat:self.listing.price] stringValue]];
        priceString = [priceString stringByAppendingString:@" / day"];
        self.priceLabel.text = priceString;
    }
    self.calendarManager = [JTCalendarManager new];
    self.calendarManager.delegate = self;
    [self.calendarManager setMenuView:self.calendarMenuView];
    [self.calendarManager setContentView:self.calendarContentView];
    [self.calendarManager setDate:[NSDate date]];
    self.reservations = [[NSMutableArray alloc] init];
    self.datesSelected = [[NSMutableArray alloc] init];
    self.datesReserved = [[NSMutableArray alloc] init];
    self.datesAvailable = [[NSMutableArray alloc] init];
    self.mapView.delegate = self;
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.distanceFilter = 200;
    [self.locationManager requestWhenInUseAuthorization];
    CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(self.listing.geoPoint.latitude, self.listing.geoPoint.longitude);
    MKCoordinateSpan span = MKCoordinateSpanMake(0.1, 0.1);
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinates, span);
    [self.mapView setRegion:region];
    self.mapView.layer.cornerRadius = 20;
    self.mapView.layer.masksToBounds = YES;
    PFQuery *listingQuery = [PFQuery queryWithClassName:@"Listing"];
    [listingQuery whereKey:@"objectId" equalTo:[self.listing objectId] ];
    [listingQuery includeKey: @"availabilities"];
    [listingQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf){
            Listing *listing = (Listing *) objects[0];
            for(int i = 0; i < listing.availabilities.count; i++){
                TimeInterval *interval = (TimeInterval *) listing.availabilities[i];
                NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:interval.startDate endDate:interval.endDate];
                [strongSelf.datesAvailable addObject:dateInterval];
            }
            PFQuery *reservationQuery = [PFQuery queryWithClassName:@"Reservation"];
            [reservationQuery whereKey:@"itemId" equalTo: [strongSelf.listing objectId]];
            [reservationQuery includeKey:@"dates"];
            [reservationQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if(error == nil){
                    for(int i = 0; i < objects.count; i++){
                        Reservation *reservation = (Reservation *) objects[i];
                        NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:reservation.dates.startDate endDate:reservation.dates.endDate];
                        [strongSelf.reservations addObject:reservation];
                        [strongSelf.datesReserved addObject:dateInterval];
                    }
                    [strongSelf.calendarManager reload];
                    [strongSelf fetchDynamicPrices];
                }else{
                    NSLog(@"END: Error in querying reservations");
                }
            }];
        }else{
            NSLog(@"END: Error in querying listing in details view");
        }
    }];
    [self setReserveButtonText];
    CLLocationCoordinate2D listingCoordinate = CLLocationCoordinate2DMake(self.listing.geoPoint.latitude, self.listing.geoPoint.longitude);
    MKPointAnnotation *pa = [[MKPointAnnotation alloc] init];
    pa.coordinate = listingCoordinate;
    pa.title = @"Listing Location";
    [self.mapView addAnnotation:pa];
}

- (IBAction)didTapBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didReserveNow:(id)sender {
    Reservation *reservation = [Reservation new];
    reservation.itemId = [self.listing objectId];
    reservation.leaseeId = [[PFUser currentUser] objectId];
    reservation.leaserId = self.listing.ownerId;
    reservation.dates = [self reservationTimeInterval];
    reservation.status = @"UNCONFIRMED";
    [reservation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(error == nil){
            [self.listing addObject:reservation forKey:@"reservations"];
            [self.listing saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if(succeeded == YES){
                    NSLog(@"END: Successfully saved reservation");
                } else{
                    NSLog(@"END: Error in saving reservation");
                }
            }];
        } else {
            NSLog(@"%@", error);
        }
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(TimeInterval *)reservationTimeInterval {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:TRUE];
    [self.datesSelected sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSDate *prevDate = self.datesSelected[0];
    for(int i = 1; i < self.datesSelected.count; i++) {
        NSDate *currDate = self.datesSelected[i];
        NSTimeInterval timeInterval = [currDate timeIntervalSinceDate:prevDate];
        if(timeInterval > 86400.0 || timeInterval < 0) { // days are not contiguous
            NSLog(@"END: Dates are not contiguous");
        }
        prevDate = currDate;
    }
    TimeInterval *result = [TimeInterval new];
    result.startDate = self.datesSelected[0];
    result.endDate = self.datesSelected[self.datesSelected.count - 1];
    return result;
}

- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(JTCalendarDayView *)dayView {
    dayView.circleView.hidden = NO;
    if([self.datesToPrices objectForKey:dayView.date] != nil && self.listing.dynamicPrice) {
        dayView.textLabel.text = [dayView.textLabel.text stringByAppendingFormat: @"$\r%@",[[self.datesToPrices objectForKey:dayView.date] stringValue]];
        [dayView.textLabel setNumberOfLines:0];
        [dayView.textLabel setFont:[UIFont systemFontOfSize:10]];
    }
    if([self isInDatesSelected:dayView.date]){ // date is selected
        dayView.circleView.backgroundColor = [self colorFromHexString:@"#E0CCCC"];
    } else if([self isDateReserved:dayView.date] == YES){ // date is reserved already
        dayView.circleView.backgroundColor = [self colorFromHexString:@"#8D8D9E"];
    } else if([self isDateAvailable:dayView.date] == YES){ // date is available
        dayView.circleView.backgroundColor = [self colorFromHexString:@"#AAB6CC"];
        NSDate *today = [NSDate date];
        if([today compare:dayView.date] == NSOrderedAscending){
            [self.datesForDynamicPricingSet addObject:dayView.date];
        }
    } else{ // date not avaiable
        dayView.circleView.hidden = YES;
    }
}

- (BOOL)isDateReserved:(NSDate *)date {
    for(int i = 0; i < self.datesReserved.count; i++) {
        NSDateInterval *interval = self.datesReserved[i];
        Reservation *reservation = (Reservation *) self.reservations[i];
        if([interval containsDate:date] == YES && [reservation.status isEqualToString:@"CONFIRMED"]){
            return YES;
        }
    }
    return NO;
}

- (BOOL)isDateAvailable:(NSDate *)date {
    // TODO: make dates before today not available
    NSDate *today = [self dateWithHour:0 minute:0 second:0];
    if([today compare:date] == NSOrderedDescending) return  NO;
    if(self.listing.isAlwaysAvailable == YES) return YES;
    for(int i = 0; i < self.datesAvailable.count; i++){
        NSDateInterval *interval = self.datesAvailable[i];
        if([interval containsDate:date] == YES){
            return YES;
        }
    }
    return NO;
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(JTCalendarDayView *)dayView {
    // Don't select date if not available
    if([self isDateAvailable:dayView.date] == NO || [self isDateReserved:dayView.date] == YES) return;
    
    if([self isInDatesSelected:dayView.date]){
        [self.datesSelected removeObject:dayView.date];
    } else{ // select date
        [self.datesSelected addObject:dayView.date];
    }
    [self setReserveButtonText];
    [self.calendarManager reload];
}

- (void)fetchDynamicPrices {
    NSMutableArray<NSDate *> *dates = [[self.datesForDynamicPricingSet allObjects] mutableCopy];
    self.dateRanges = [self getDynamicPriceDateRanges:dates];
    __weak typeof(self) weakSelf = self;
    fetchDynamicPrice(self.listing, self.dateRanges, ^(NSDictionary<NSNumber *, NSNumber *> * result, NSError * _Nonnull error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil) {
            if(strongSelf) {
                NSArray *keys = result.allKeys;
                for(NSNumber *key in keys) {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[key doubleValue] / 1000];
                    strongSelf.datesToPrices[date] = result[key];
                }
                [strongSelf.calendarManager reload];
            }
        } else{
            NSLog(@"%@", error);
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ Error", error.domain]
                                           message:@"Could not fetch dynamic prices. Please try again."
                                           preferredStyle:UIAlertControllerStyleAlert];
             
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
               handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}

- (NSMutableArray *)getDynamicPriceDateRanges:(NSMutableArray<NSDate *> *)dates {
    double k24HoursInSeconds = 86400.0;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if(dates.count == 0) {
        return result;
    }
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES];
    [dates sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSDate *startDate = dates[0];
    NSDate *endDate = startDate;
    for (int i = 1; i < dates.count; i++) {
        NSDate *currDate = dates[i];
        NSTimeInterval timeInterval = [currDate timeIntervalSinceDate:endDate];
        NSLog(@"%f", timeInterval);
        if(timeInterval <= k24HoursInSeconds && timeInterval >= 0){ // days are contiguous
            endDate = currDate;
        } else { // dates are not contiguous
            NSMutableArray<NSNumber *> *dateRange = [NSMutableArray<NSNumber *> new];
            [dateRange addObject:@(startDate.timeIntervalSince1970)];
            [dateRange addObject:@(endDate.timeIntervalSince1970)];
            [result addObject:dateRange];
            startDate = currDate;
            endDate = currDate;
        }
    }
    NSMutableArray<NSNumber *> *dateRange = [NSMutableArray<NSNumber *> new];
    [dateRange addObject:@(startDate.timeIntervalSince1970)];
    [dateRange addObject:@(endDate.timeIntervalSince1970)];
    [result addObject:dateRange];
    return result;
}

- (BOOL)isInDatesSelected:(NSDate *)date {
    for(NSDate *dateSelected in self.datesSelected){
        if([self.calendarManager.dateHelper date:dateSelected isTheSameDayThan:date]) {
            return YES;
        }
    }
    return NO;
}

- (void)setReserveButtonText {
    if(self.datesSelected.count == 0) {
        [self.reserveNowButton setTitle:@"Please select day(s) to reserve item" forState:UIControlStateNormal];
    }else {
        CGFloat total = 0.0;
        if(self.listing.dynamicPrice) {
            for(NSDate *date in self.datesSelected){
                total += [[self.datesToPrices objectForKey:date]doubleValue];
            }
        } else {
            NSRange range = NSMakeRange(1, self.priceLabel.text.length - 6);
            NSString *substring = [self.priceLabel.text substringWithRange:range];
            total = [substring floatValue] * self.datesSelected.count;
        }
        NSString *buttonText = @"Reserve now for $";
        buttonText = [buttonText stringByAppendingString:[[NSNumber numberWithFloat:total] stringValue]];
        [self.reserveNowButton setTitle:buttonText forState:UIControlStateNormal];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    [self.locationManager startUpdatingLocation];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ImageCarouselCollectionViewCell *cell = [self.carouselCollectionView dequeueReusableCellWithReuseIdentifier:@"ImageCarouselCollectionViewCell" forIndexPath:indexPath];
    PFFileObject *image = (PFFileObject *) self.listing.images[indexPath.row];
    NSURL *imageURL = [NSURL URLWithString:image.url];
    [cell.cellImage setImageWithURL: imageURL];
    cell.cellImage.contentMode = UIViewContentModeScaleAspectFit;
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.listing.images.count;
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
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

@end
