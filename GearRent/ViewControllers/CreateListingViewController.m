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
#import "../Models/TimeInterval.h"
#import "../Models/Item.h"
#import "MapKit/MapKit.h"
#import "CoreLocation/CoreLocation.h"

@interface CreateListingViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, JTCalendarDelegate,ProfileImagePickerViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UIView *calendarView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UICollectionView *imageCarouselCollectionView;
@property (strong, nonatomic) NSMutableArray *carouselImages;
@property (strong, nonatomic) NSMutableArray *datesSelected;
@property (weak, nonatomic) IBOutlet UILabel *addImagesLabel;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *priceTextField;
@property (weak, nonatomic) IBOutlet UITextField *cityTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UISwitch *isAlwaysAvailableSwitch;


- (IBAction)didAddImages:(id)sender;
- (IBAction)didList:(id)sender;
- (IBAction)didSwitchAvailability:(id)sender;
- (IBAction)didTapBack:(id)sender;

@end

@implementation CreateListingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.nameLabel.text =  [PFUser currentUser][@"name"];
    self.imageCarouselCollectionView.delegate = self;
    self.imageCarouselCollectionView.dataSource = self;
    self.carouselImages = [[NSMutableArray alloc] init];
    self.datesSelected = [[NSMutableArray alloc] init];
    
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
    
    UITapGestureRecognizer *fingerTap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(handleMapFingerTap:)];
    fingerTap.numberOfTapsRequired = 1;
    fingerTap.numberOfTouchesRequired = 1;
    [self.mapView addGestureRecognizer:fingerTap];
}

- (IBAction)didList:(id)sender {
    Item *newItem = [Item new];
    newItem.title = self.titleTextField.text;
    newItem.itemDescription = self.descriptionTextField.text;
    newItem.price = [self.priceTextField.text floatValue];
    newItem.images = [self imagesToPFFiles:self.carouselImages];
    newItem.videoURL = @"";
    newItem.ownerId = [[PFUser currentUser] objectId];
    newItem.tags = [[NSMutableArray alloc] init];
    CLLocationCoordinate2D itemCoordinates = self.mapView.annotations[0].coordinate;
    newItem.geoPoint = [PFGeoPoint geoPointWithLatitude: itemCoordinates.latitude longitude:itemCoordinates.longitude];
    newItem.city = self.cityTextField.text;
    newItem.reservations = [[NSMutableArray alloc] init];
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

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if(status == kCLAuthorizationStatusAuthorizedWhenInUse){
        [self.locationManager startUpdatingLocation];
    }
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager{
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    MKCoordinateSpan span = MKCoordinateSpanMake(0.1, 0.1);
    MKCoordinateRegion region = MKCoordinateRegionMake(locations[0].coordinate, span);
    [self.mapView setRegion:region];
}

- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(JTCalendarDayView *)dayView{
    if([self.isAlwaysAvailableSwitch isOn] == YES){
        dayView.circleView.hidden = NO;
    } else if(self.datesSelected.count == 0){
        dayView.circleView.hidden = YES;
    } else{
        dayView.circleView.hidden = [dayView.circleView  isHidden];
    }
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(JTCalendarDayView *)dayView{
    // deselect date
    if([self.isAlwaysAvailableSwitch isOn] == YES){
        [self.datesSelected removeAllObjects];
        [self.isAlwaysAvailableSwitch setOn:NO];
        [self.calendarManager reload];
    }
    if([self isInDatesSelected:dayView.date]){
        [self.datesSelected removeObject:dayView.date];
        dayView.circleView.hidden = YES;
        [UIView transitionWithView:dayView
                          duration:.3
                           options:0
                        animations:^{
                            [self.calendarManager reload];
                            dayView.circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
                        } completion:nil];
        
    } else{ // select date
        [self.datesSelected addObject:dayView.date];
        
        dayView.circleView.hidden = NO;
        dayView.circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
        [UIView transitionWithView:dayView
                          duration:.3
                           options:0
                        animations:^{
                            [self.calendarManager reload];
                            dayView.circleView.transform = CGAffineTransformIdentity;
                        } completion:nil];
    }
    
}

- (BOOL)isInDatesSelected:(NSDate *)date{
    for(NSDate *dateSelected in self.datesSelected){
        if([self.calendarManager.dateHelper date:dateSelected isTheSameDayThan:date]){
            return YES;
        }
    }
    
    return NO;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ImageCarouselCollectionViewCell *cell = [self.imageCarouselCollectionView dequeueReusableCellWithReuseIdentifier:@"ImageCarouselCollectionViewCell" forIndexPath:indexPath];
    cell.cellImage.image = self.carouselImages[indexPath.row];
    cell.cellImage.contentMode = UIViewContentModeScaleAspectFit;
//    cell.contentView.frame.size = CGSizeMake(self.imageCarouselCollectionView.frame.size.width, self.imageCarouselCollectionView.frame.size.height);
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.carouselImages.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (IBAction)didSwitchAvailability:(id)sender {
    [self.datesSelected removeAllObjects];
    [self.calendarManager reload];
}

- (NSMutableArray *) getTimeIntervals: (NSMutableArray *) dates{
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

- (NSMutableArray *) imagesToPFFiles: (NSMutableArray *) images{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for(int i = 0 ; i < images.count; i ++){
        [result addObject:[self getPFFileFromImage: (UIImage *) images[i]]];
    }
    return result;
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

- (void)dismissKeyboard{
     [self.view endEditing:YES];
}

- (PFFileObject *)getPFFileFromImage: (UIImage * _Nullable)image {
 
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
