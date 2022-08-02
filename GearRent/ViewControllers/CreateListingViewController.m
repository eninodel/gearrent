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
#import "Listing.h"
#import "Reservation.h"
#import "MapKit/MapKit.h"
#import "CoreLocation/CoreLocation.h"
#import "GNGeoHash.h"
#import "APIManager.h"
#import "Category.h"

@interface CreateListingViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, JTCalendarDelegate,ProfileImagePickerViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
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
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UISwitch *isAlwaysAvailableSwitch;
@property (strong, nonatomic) IBOutlet UIButton *addImagesButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteListingButton;
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationTitle;
@property (strong, nonatomic) IBOutlet UIPickerView *categoriesPicker;
@property(strong, nonatomic) NSArray<Category *> *categories;
@property (strong, nonatomic) IBOutlet UISwitch *dynamicPricingSwitch;
@property (strong, nonatomic) IBOutlet UITextField *minimumPriceTextField;


- (IBAction)didAddImages:(id)sender;
- (IBAction)didList:(id)sender;
- (IBAction)didSwitchAvailability:(id)sender;
- (IBAction)didTapBack:(id)sender;
- (IBAction)didDeleteListing:(id)sender;
- (IBAction)didSwitchDynamicPrice:(id)sender;

@end

@implementation CreateListingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.minimumPriceTextField setHidden:YES];
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
    self.categoriesPicker.delegate = self;
    self.categoriesPicker.dataSource = self;
    __weak typeof(self) weakSelf = self;
    void(^completion)(NSArray<Category *> *, NSError *) = ^void(NSArray<Category*> *categories, NSError *error){
        typeof(self) strongSelf = weakSelf;
        if(error == nil){
            if(strongSelf){
                strongSelf.categories = categories;
                [strongSelf.categoriesPicker reloadAllComponents];
                if(strongSelf.listing){
                    [strongSelf.categoriesPicker selectRow:[strongSelf indexOfListingCategory] inComponent:0 animated:YES];
                }
            }
        } else{
            NSLog(@"%@", error);
        }
    };
    fetchAllCategories(completion);
    if(self.listing != nil){
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        [self.minimumPriceTextField setHidden: !self.listing.dynamicPrice];
        self.minimumPriceTextField.text = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat:self.listing.minPrice]];
        [self.priceTextField setHidden: self.listing.dynamicPrice];
        [self.dynamicPricingSwitch setOn:self.listing.dynamicPrice];
        self.navigationItem.title = @"Edit Listing";
        self.deleteListingButton.hidden = NO;
        self.addImagesButton.hidden = YES;
        self.titleTextField.text = self.listing.title;
        NSString *price = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat: self.listing.price]];
        self.priceTextField.text = price;
        self.locationLabel.text = self.listing.location;
        self.descriptionTextField.text = self.listing.itemDescription;
        [self.isAlwaysAvailableSwitch setOn: self.listing.isAlwaysAvailable];
        CLLocationCoordinate2D listingCoordinate = CLLocationCoordinate2DMake(self.listing.geoPoint.latitude, self.listing.geoPoint.longitude);
        MKPointAnnotation *pa = [[MKPointAnnotation alloc] init];
        pa.coordinate = listingCoordinate;
        pa.title = @"Item Location";
        [self.mapView addAnnotation:pa];
        PFQuery *listingQuery = [PFQuery queryWithClassName:@"Listing"];
        [listingQuery whereKey:@"objectId" equalTo:[self.listing objectId] ];
        [listingQuery includeKey: @"availabilities"];
        __weak typeof(self) weakSelf = self;
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
                            [strongSelf.datesReserved addObject:dateInterval];
                        }
                        [strongSelf populateDatesSelected];
                        [strongSelf.calendarManager reload];
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

- (NSInteger)indexOfListingCategory {
    for(int i = 0; i < self.categories.count; i ++){
        if([[self.categories[i] objectId] isEqualToString:self.listing.categoryId]){
            return i;
        }
    }
    return 0;
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
    Listing *newListing = [Listing new];
    newListing.reservations = [[NSMutableArray alloc] init];
    newListing.images = [self imagesToPFFiles:self.carouselImages];
    if(self.listing != nil){
        newListing = self.listing;
    }
    newListing.dynamicPrice = [self.dynamicPricingSwitch isOn];
    newListing.title = self.titleTextField.text;
    newListing.itemDescription = self.descriptionTextField.text;
    newListing.price = [self.priceTextField.text floatValue];
    newListing.minPrice = [self.minimumPriceTextField.text floatValue];
    newListing.videoURL = @"";
    newListing.ownerId = [[PFUser currentUser] objectId];
    newListing.tags = [[NSMutableArray alloc] init];
    newListing.categoryId = [(Category *)self.categories[[self.categoriesPicker selectedRowInComponent:0]] objectId];
    NSLog(@"%@", self.mapView.annotations);
    for(int i = 0; i < self.mapView.annotations.count; i++){
        NSObject *annotation = self.mapView.annotations[i];
        if([annotation isKindOfClass: [MKPointAnnotation class]]){
            CLLocationCoordinate2D listingCoordinates = self.mapView.annotations[i].coordinate;
            newListing.geoPoint = [PFGeoPoint geoPointWithLatitude: listingCoordinates.latitude longitude:listingCoordinates.longitude];
        }
    }
    newListing.location = self.locationLabel.text;
    newListing.availabilities =  [self getTimeIntervals:self.datesSelected];
    newListing.isAlwaysAvailable = self.isAlwaysAvailableSwitch.on;
    // TODO: add utils class with constants such as geohash precision
    GNGeoHash *geohash = [GNGeoHash withCharacterPrecision:newListing.geoPoint.latitude  andLongitude:newListing.geoPoint.longitude andNumberOfCharacters:7];
    newListing.geohash = [geohash toBase32];
    [newListing saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(succeeded){
            NSLog(@"END: Listing successfully saved");
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
    pa.title = @"Listing Location";
    [self.mapView addAnnotation:pa];
    __weak typeof(self) weakSelf = self;
    void(^completion)(NSString *, NSError *) = ^void(NSString *response, NSError *error){
        typeof(self) strongSelf = weakSelf;
        if(error == nil){
            if(strongSelf){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.locationLabel setText:response];
                });
            }
        } else{
            NSLog(@"%@", error);
        }
    };
    CLLocation *location = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
    [[APIManager alloc] fetchNearestCity:location completion:completion];
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
    if([self isDateReserved:dayView.date]){ // date is reserved already
        dayView.circleView.backgroundColor = UIColor.blackColor;
    } else if([self isInDatesSelected: dayView.date]){ // date is available
        dayView.circleView.backgroundColor = UIColor.blueColor;
    } else if ([self.isAlwaysAvailableSwitch isOn] == NO){ // date not avaiable
        dayView.circleView.hidden = YES;
    }
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(JTCalendarDayView *)dayView {
    // deselect date
    if([self isDateReserved:dayView.date]) return;
    if([self.isAlwaysAvailableSwitch isOn]){
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
    if([self.isAlwaysAvailableSwitch isOn]) return YES;
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
        if([interval containsDate:date]){
            return YES;
        }
    }
    return NO;
}

- (BOOL)isDateAvailable:(NSDate *)date {
    if(self.listing.isAlwaysAvailable) return YES;
    for(int i = 0; i < self.datesAvailable.count; i++){
        NSDateInterval *interval = self.datesAvailable[i];
        if([interval containsDate:date]){
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

- (IBAction)didSwitchDynamicPrice:(id)sender {
    if([self.dynamicPricingSwitch isOn]) {
        [self.minimumPriceTextField setHidden:NO];
        [self.priceTextField setHidden: YES];
    } else {
        [self.minimumPriceTextField setHidden:YES];
        [self.priceTextField setHidden: NO];
    }
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

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.categories.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    Category *category = self.categories[row];
    return category[@"title"];
}

@end
