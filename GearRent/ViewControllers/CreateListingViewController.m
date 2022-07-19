//
//  CreateListingViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/7/22.
//

#import "CreateListingViewController.h"
#import "ImageCarouselCollectionViewCell.h"
#import <JTCalendar/JTCalendar.h>
#import "ProfileImagePickerViewController.h"
#import "UIImageView+AFNetworking.h"
#import "TimeInterval.h"
#import "Item.h"
#import "Reservation.h"
#import "MapKit/MapKit.h"
#import "CoreLocation/CoreLocation.h"

@interface CreateListingViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, JTCalendarDelegate,ProfileImagePickerViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate>
@property (strong, nonatomic) IBOutlet UIView *calendarView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UICollectionView *imageCarouselCollectionView;
@property (strong, nonatomic) NSMutableArray *carouselImages;
@property (strong, nonatomic) NSMutableArray *datesAvailable;
@property (strong, nonatomic) NSMutableArray *datesSelected;
@property (strong, nonatomic) NSMutableArray *datesReserved;
@property (strong, nonatomic) IBOutlet UILabel *addImagesLabel;
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet UITextField *priceTextField;
@property (strong, nonatomic) IBOutlet UITextField *cityTextField;
@property (strong, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UISwitch *isAlwaysAvailableSwitch;
@property (strong, nonatomic) IBOutlet UIButton *addImagesButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteListingButton;
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationTitle;


- (IBAction)didAddImages:(id)sender;
- (IBAction)didList:(id)sender;
- (IBAction)didSwitchAvailability:(id)sender;
- (IBAction)didTapBack:(id)sender;
- (IBAction)didDeleteListing:(id)sender;

@end

@implementation CreateListingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.deleteListingButton.hidden = YES;
    self.navigationItem.title = @"Create a Listing";
    self.nameLabel.text =  [PFUser currentUser][@"name"];
    self.imageCarouselCollectionView.delegate = self;
    self.imageCarouselCollectionView.dataSource = self;
    self.carouselImages = [[NSMutableArray alloc] init];
    self.datesSelected = [[NSMutableArray alloc] init];
    self.datesAvailable = [[NSMutableArray alloc] init];
    self.datesReserved = [[NSMutableArray alloc] init];
    self.imageCarouselCollectionView.hidden = true;
    self.calendarManager = [JTCalendarManager new];
    self.calendarManager.delegate = self;
    [self.calendarManager setMenuView:self.calendarMenuView];
    [self.calendarManager setContentView:self.calendarContentView];
    [self.calendarManager setDate:[NSDate date]];
    self.scrollView.scrollEnabled = YES;
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.cancelsTouchesInView = NO;
    self.mapView.delegate = self;
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.distanceFilter = 200;
    [self.locationManager requestWhenInUseAuthorization];
    UITapGestureRecognizer *fingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapFingerTap:)];
    fingerTap.numberOfTapsRequired = 1;
    fingerTap.numberOfTouchesRequired = 1;
    [self.mapView addGestureRecognizer:fingerTap];
    if(self.listing != nil){
        self.navigationItem.title = @"Edit Listing";
        self.deleteListingButton.hidden = NO;
        self.addImagesButton.hidden = YES;
        self.titleTextField.text = self.listing.title;
        self.priceTextField.text = [[NSNumber numberWithFloat: self.listing.price] stringValue];
        self.cityTextField.text = self.listing.city;
        self.descriptionTextField.text = self.listing.itemDescription;
        [self.isAlwaysAvailableSwitch setOn: self.listing.isAlwaysAvailable];
        CLLocationCoordinate2D itemCoordinate = CLLocationCoordinate2DMake(self.listing.geoPoint.latitude, self.listing.geoPoint.longitude);
        MKPointAnnotation *pa = [[MKPointAnnotation alloc] init];
        pa.coordinate = itemCoordinate;
        pa.title = @"Item Location";
        [self.mapView addAnnotation:pa];
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
                            [self.datesReserved addObject:dateInterval];
                        }
                        [self populateDatesSelected];
                        [self.calendarManager reload];
                    }else{
                        NSLog(@"END: Error in querying reservations");
                    }
                }];
            }else{
                NSLog(@"END: Error in querying listing in details view");
            }
        }];
        self.imageCarouselCollectionView.hidden = NO;
        self.addImagesLabel.hidden = true;
        [self.imageCarouselCollectionView reloadData];
    }
}

- (void)populateDatesSelected {
    for(int i = 0; i < self.datesAvailable.count; i++){
        NSDateInterval *interval = (NSDateInterval *) self.datesAvailable[i];
        NSDate *curr = interval.startDate;
        while([interval containsDate:curr]){
            [self.datesSelected addObject:curr];
            curr = [NSDate dateWithTimeInterval:(24*60*60) sinceDate:curr];
        }
    }
}

- (IBAction)didList:(id)sender {
    Item *newItem = [Item new];
    newItem.reservations = [[NSMutableArray alloc] init];
    newItem.images = [self imagesToPFFiles:self.carouselImages];
    if(self.listing != nil){
        newItem = self.listing;
    }
    newItem.title = self.titleTextField.text;
    newItem.itemDescription = self.descriptionTextField.text;
    newItem.price = [self.priceTextField.text floatValue];
    newItem.videoURL = @"";
    newItem.ownerId = [[PFUser currentUser] objectId];
    newItem.tags = [[NSMutableArray alloc] init];
    NSLog(@"%@", self.mapView.annotations);
    for(int i = 0; i < self.mapView.annotations.count; i++){
        NSObject *annotation = self.mapView.annotations[i];
        if([annotation isKindOfClass: [MKPointAnnotation class]]){
            CLLocationCoordinate2D itemCoordinates = self.mapView.annotations[i].coordinate;
            newItem.geoPoint = [PFGeoPoint geoPointWithLatitude: itemCoordinates.latitude longitude:itemCoordinates.longitude];
        }
    }
    newItem.city = self.cityTextField.text;
    newItem.availabilities =  [self getTimeIntervals:self.datesSelected];
    newItem.isAlwaysAvailable = [self.isAlwaysAvailableSwitch isOn];
    
    [newItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(succeeded){
            NSLog(@"END: Item successfully saved");
            [self dismissViewControllerAnimated:YES completion:nil];
        } else{
            NSLog(@"%@", error.description);
        }
    }];
}

- (void)handleMapFingerTap:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if(self.mapView.annotations.count > 0){
        NSArray *annotations = self.mapView.annotations;
        [self.mapView removeAnnotations:annotations];
    }
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    MKPointAnnotation *pa = [[MKPointAnnotation alloc] init];
    pa.coordinate = touchMapCoordinate;
    pa.title = @"Item Location";
    [self.mapView addAnnotation:pa];
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

- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(JTCalendarDayView *)dayView {
    dayView.circleView.hidden = NO;
    if([self isDateReserved:dayView.date] == YES){ // date is reserved already
        dayView.circleView.backgroundColor = UIColor.blackColor;
    } else if([self isInDatesSelected: dayView.date] == YES){ // date is available
        dayView.circleView.backgroundColor = UIColor.blueColor;
    } else if ([self.isAlwaysAvailableSwitch isOn] == NO){ // date not avaiable
        dayView.circleView.hidden = YES;
    }
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(JTCalendarDayView *)dayView {
    // deselect date
    if([self isDateReserved:dayView.date] == YES) return;
    if([self.isAlwaysAvailableSwitch isOn] == YES){
        [self.datesSelected removeAllObjects];
        [self.isAlwaysAvailableSwitch setOn:NO];
    } else if([self isInDatesSelected:dayView.date]){
        [self.datesSelected removeObject:dayView.date];
    } else{ // select date
        [self.datesSelected addObject:dayView.date];
    }
    [self.calendarManager reload];
}

- (BOOL)isInDatesSelected:(NSDate *)date {
    if([self.isAlwaysAvailableSwitch isOn] == YES) return YES;
    for(NSDate *dateSelected in self.datesSelected){
        if([self.calendarManager.dateHelper date:dateSelected isTheSameDayThan:date]){
            return YES;
        }
    }
    return NO;
}

- (BOOL)isDateReserved:(NSDate *)date {
    for(int i = 0; i < self.datesReserved.count; i++){
        NSDateInterval *interval = self.datesReserved[i];
        if([interval containsDate:date] == YES){
            return YES;
        }
    }
    return NO;
}

- (BOOL)isDateAvailable:(NSDate *)date {
    if(self.listing.isAlwaysAvailable == YES) return YES;
    for(int i = 0; i < self.datesAvailable.count; i++){
        NSDateInterval *interval = self.datesAvailable[i];
        if([interval containsDate:date] == YES){
            return YES;
        }
    }
    return NO;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ImageCarouselCollectionViewCell *cell = [self.imageCarouselCollectionView dequeueReusableCellWithReuseIdentifier:@"ImageCarouselCollectionViewCell" forIndexPath:indexPath];
    if(self.listing != nil){
        PFFileObject *image = (PFFileObject *) self.listing.images[indexPath.row];
        NSURL *imageURL = [NSURL URLWithString: image.url];
        [cell.cellImage setImageWithURL: imageURL];
    } else{
        cell.cellImage.image = self.carouselImages[indexPath.row];
    }
    cell.cellImage.contentMode = UIViewContentModeScaleAspectFit;
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if(self.listing != nil){
        return self.listing.images.count;
    }
    return self.carouselImages.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (IBAction)didSwitchAvailability:(id)sender {
    [self.datesSelected removeAllObjects];
    [self.calendarManager reload];
}

- (NSMutableArray *)getTimeIntervals:(NSMutableArray *)dates {
    NSMutableArray *result =[[NSMutableArray alloc] init];
    if(dates.count == 0){
        return result;
    }
    NSDate *startDate = self.datesSelected[0];
    NSDate *endDate = startDate;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:TRUE];
    [self.datesSelected sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    for (int i = 1; i < self.datesSelected.count; i++) {
        NSDate *currDate = (NSDate *) self.datesSelected[i];
        NSTimeInterval timeInterval = [currDate timeIntervalSinceDate:endDate];
        NSLog(@"%f", timeInterval);
        if(timeInterval <= 86400.0 && timeInterval >= 0){ // days are contiguous
            endDate = currDate;
        } else{ // dates are not contiguous
            TimeInterval *interval = [TimeInterval new];
            interval.startDate = startDate;
            interval.endDate = endDate;
            [result addObject:interval];
            startDate = currDate;
            endDate = currDate;
        }
    }
    TimeInterval *interval = [TimeInterval new];
    interval.startDate = startDate;
    interval.endDate = endDate;
    [result addObject:interval];
    return result;
}

- (NSMutableArray *)imagesToPFFiles:(NSMutableArray *)images {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for(int i = 0 ; i < images.count; i ++){
        [result addObject:[self getPFFileFromImage: (UIImage *) images[i]]];
    }
    return result;
}

- (IBAction)didDeleteListing:(id)sender {
    [self.listing deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(error == nil){
            NSLog(@"END: Successfully deleted listing");
            [self dismissViewControllerAnimated:YES completion:nil];
        }else{
            NSLog(@"END: Failed to delete listing");
        }
    }];
}

- (IBAction)didTapBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didAddImages:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"ProfileImagePickerNavigationController"];
    [self presentViewController:navigationVC animated:YES completion:nil];
    ProfileImagePickerViewController *profileImagePickerVC = (ProfileImagePickerViewController *) navigationVC.topViewController;
    profileImagePickerVC.delegate = self;
}

- (void)didPickProfileImage:(nonnull UIImage *)image {
    self.addImagesLabel.hidden = YES;
    self.imageCarouselCollectionView.hidden = NO;
    [self.carouselImages addObject:image];
    [self.imageCarouselCollectionView reloadData];
}

- (void)dismissKeyboard {
     [self.view endEditing:YES];
}

- (PFFileObject *)getPFFileFromImage:(UIImage * _Nullable)image {
    // check if image is not nil
    if (!image) {
        return nil;
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    // get image data and check if that is not nil
    if (!imageData) {
        return nil;
    }
    return [PFFileObject fileObjectWithName:@"image.png" data:imageData];
}

@end
