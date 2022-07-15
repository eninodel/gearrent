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
#import "../Models/TimeInterval.h"
#import "../Models/Item.h"
#import "../Models/Reservation.h"

@interface DetailsViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, JTCalendarDelegate, MKMapViewDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *carouselCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *ownerLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *reserveNowButton;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *reservations;
@property (strong, nonatomic) NSMutableArray *datesSelected;
@property (strong, nonatomic) NSMutableArray *datesReserved;
@property (strong, nonatomic) NSMutableArray *datesAvailable;

- (IBAction)didReserveNow:(id)sender;
- (IBAction)didTapBack:(id)sender;

@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.carouselCollectionView.delegate = self;
    self.carouselCollectionView.dataSource = self;
    self.titleLabel.text = self.listing.title;
    self.locationLabel.text = self.listing.city;
    self.descriptionLabel.text = self.listing.itemDescription;
    PFQuery *query = [PFUser query];
    [query whereKey:@"objectId" equalTo: self.listing.ownerId];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error == nil){
            PFUser *owner = (PFUser *) objects[0];
            self.ownerLabel.text = owner[@"name"];
        } else{
            NSLog(@"END: Error in getting user in DetailsViewController");
        }
    }];
    NSString *priceString = @"$";
    priceString = [priceString stringByAppendingString:[[NSNumber numberWithFloat:self.listing.price] stringValue]];
    priceString = [priceString stringByAppendingString:@" / day"];
    self.priceLabel.text = priceString;
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
    PFQuery *listingQuery = [PFQuery queryWithClassName:@"Listing"];
    [listingQuery whereKey:@"objectId" equalTo:[self.listing objectId] ];
    [listingQuery includeKey: @"availabilities"];
    [listingQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error == nil){
            Item *item = (Item *) objects[0];
            for(int i = 0; i < item.availabilities.count; i++){
                TimeInterval *interval = (TimeInterval *) item.availabilities[i];
                NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:interval.startDate endDate:interval.endDate];
                [self.datesAvailable addObject:dateInterval];
            }
            PFQuery *reservationQuery = [PFQuery queryWithClassName:@"Reservation"];
            [reservationQuery whereKey:@"itemId" equalTo: [self.listing objectId]];
            [reservationQuery includeKey:@"dates"];
            [reservationQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if(error == nil){
                    for(int i = 0; i < objects.count; i++){
                        Reservation *reservation = (Reservation *) objects[i];
                        NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:reservation.dates.startDate endDate:reservation.dates.endDate];
                        [self.reservations addObject:reservation];
                        [self.datesReserved addObject:dateInterval];
                    }
                    [self.calendarManager reload];
                }else{
                    NSLog(@"END: Error in querying reservations");
                }
            }];
        }else{
            NSLog(@"END: Error in querying listing in details view");
        }
    }];
    [self setReserveButtonText];
    CLLocationCoordinate2D itemCoordinate = CLLocationCoordinate2DMake(self.listing.geoPoint.latitude, self.listing.geoPoint.longitude);
    MKPointAnnotation *pa = [[MKPointAnnotation alloc] init];
    pa.coordinate = itemCoordinate;
    pa.title = @"Item Location";
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
    [self.listing addObject:reservation forKey:@"reservations"];
    [self.listing saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(succeeded == YES){
            NSLog(@"END: Successfully saved reservation");
        } else{
            NSLog(@"END: Error in saving reservation");
        }
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(TimeInterval *)reservationTimeInterval {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:TRUE];
    [self.datesSelected sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSDate *prevDate = self.datesSelected[0];
    for(int i = 1; i < self.datesSelected.count; i++){
        NSDate *currDate = self.datesSelected[i];
        NSTimeInterval timeInterval = [currDate timeIntervalSinceDate:prevDate];
        if(timeInterval > 86400.0 || timeInterval < 0){ // days are not contiguous
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
    if([self isInDatesSelected:dayView.date]){ // date is selected
        dayView.circleView.backgroundColor = UIColor.orangeColor;
    } else if([self isDateReserved:dayView.date] == YES){ // date is reserved already
        dayView.circleView.backgroundColor = UIColor.blackColor;
    } else if([self isDateAvailable:dayView.date] == YES){ // date is available
        dayView.circleView.backgroundColor = UIColor.blueColor;
    } else{ // date not avaiable
        dayView.circleView.hidden = YES;
    }
}

- (Boolean)isDateReserved:(NSDate *)date {
    for(int i = 0; i < self.datesReserved.count; i++){
        NSDateInterval *interval = self.datesReserved[i];
        Reservation *reservation = (Reservation *) self.reservations[i];
        if([interval containsDate:date] == YES && [reservation.status isEqualToString:@"ACCEPTED"]){
            return YES;
        }
    }
    return NO;
}

- (Boolean)isDateAvailable:(NSDate *)date {
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
        [self setReserveButtonText];
        [self.calendarManager reload];
        
    } else{ // select date
        [self.datesSelected addObject:dayView.date];
        [self setReserveButtonText];
        [self.calendarManager reload];
    }
}

- (BOOL)isInDatesSelected:(NSDate *)date {
    for(NSDate *dateSelected in self.datesSelected){
        if([self.calendarManager.dateHelper date:dateSelected isTheSameDayThan:date]){
            return YES;
        }
    }
    return NO;
}

- (void)setReserveButtonText {
    if(self.datesSelected.count == 0){
        [self.reserveNowButton setTitle:@"Please select day(s) to reserve item" forState:UIControlStateNormal];
    }else{
        float total = self.listing.price * self.datesSelected.count;
        NSString *buttonText = @"Reserve now for $";
        buttonText = [buttonText stringByAppendingString:[[NSNumber numberWithFloat:total] stringValue]];
        [self.reserveNowButton setTitle:buttonText forState:UIControlStateNormal];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if(status == kCLAuthorizationStatusAuthorizedWhenInUse){
        [self.locationManager startUpdatingLocation];
    }
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    MKCoordinateSpan span = MKCoordinateSpanMake(0.1, 0.1);
    MKCoordinateRegion region = MKCoordinateRegionMake(locations[0].coordinate, span);
    [self.mapView setRegion:region];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ImageCarouselCollectionViewCell *cell = [self.carouselCollectionView dequeueReusableCellWithReuseIdentifier:@"ImageCarouselCollectionViewCell" forIndexPath:indexPath];
    PFFileObject *image = (PFFileObject *) self.listing.images[indexPath.row];
    NSURL *imageURL = [NSURL URLWithString: image.url];
    [cell.cellImage setImageWithURL: imageURL];
    cell.cellImage.contentMode = UIViewContentModeScaleAspectFit;
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.listing.images.count;
}

@end
