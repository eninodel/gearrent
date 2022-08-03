//
//  GearForRentViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/5/22.
//

#import "GearForRentViewController.h"
#import "../Delegates/SceneDelegate.h"
#import "LoginViewControllers/SignInViewController.h"
#import "Parse/Parse.h"
#import "ListingTableViewCell.h"
#import "DetailsViewController.h"
#import "MapKit/MapKit.h"
#import "CoreLocation/CoreLocation.h"
#import "APIManager.h"
#import "Listing.h"
#import "Category.h"
#import "FiltersTableViewCell.h"
#import "Filter.h"

@interface GearForRentViewController ()<UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate, FiltersTableViewCellDelegate>

@property (strong, nonatomic) NSArray *tableData;
@property (strong, nonatomic) IBOutlet UITableView *listingsTableView;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UIButton *listingTypeButton;
@property (strong, nonatomic) NSMutableArray<CLLocation *> *mapPoints;
@property (strong, nonatomic) IBOutlet UIButton *removePointsButton;
@property (strong, nonatomic) IBOutlet UIButton *searchPolygonButton;
@property (strong, nonatomic) IBOutlet UITableView *FiltersTableView;
@property (strong, nonatomic) IBOutlet UIButton *FiltersButton;
@property (strong, nonatomic) NSArray<Category *> *categories;
@property (strong, nonatomic) NSMutableSet<NSString *> *selectedCategories;
@property (strong, nonatomic) NSArray<Listing *> *filteredListings;
@property (strong, nonatomic) CLLocation *userLocation;

- (IBAction)didLogOut:(id)sender;
- (IBAction)didChangeListing:(id)sender;
- (IBAction)didRemovePoints:(id)sender;
- (IBAction)didSearchPolygon:(id)sender;
- (IBAction)didTapFilters:(id)sender;

@end

@implementation GearForRentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.selectedCategories = [NSMutableSet<NSString *> new];
    self.FiltersTableView.delegate = self;
    self.FiltersTableView.dataSource = self;
    self.categories = [NSArray<Category *> new];
    self.mapPoints = [NSMutableArray<CLLocation *> new];
    self.listingsTableView.delegate = self;
    self.listingsTableView.dataSource = self;
    self.filteredListings = [NSArray<Listing *> new];
    self.mapView.hidden = YES;
    self.removePointsButton.hidden = YES;
    self.searchPolygonButton.hidden = YES;
    self.listingTypeButton.titleLabel.text = @"Map";
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
    [self.FiltersTableView setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [self fetchData];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolygon class]])
    {
        MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        renderer.strokeColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
        renderer.lineWidth   = 2;
        return renderer;
    }
    return nil;
}

- (void)handleMapFingerTap:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    MKPointAnnotation *pa = [[MKPointAnnotation alloc] init];
    pa.coordinate = touchMapCoordinate;
    pa.title = @"Polygon vertice";
    [self.mapView addAnnotation:pa];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
    [self.mapPoints addObject: location];
    [self renderMapPoints];
}

- (void)renderMapPoints {
    // TODO: create a function to validate that no polygon segments overlap
    NSUInteger count = self.mapPoints.count;
    if(self.mapView.overlays.count > 0){
        [self.mapView removeOverlays:self.mapView.overlays];
    }
    if(count > 2){
        CLLocationCoordinate2D coordinates[count];
        for(int i = 0; i < count; i++){
            coordinates[i] = self.mapPoints[i].coordinate;
        }
        MKPolygon *polygon = [MKPolygon polygonWithCoordinates: coordinates count: count];
        [self.mapView addOverlay:polygon];
    }
}

- (double)getDistance:(CLLocation *)pointA pointB:(CLLocation *)pointB{
    return sqrt(pow(pointA.coordinate.latitude - pointB.coordinate.latitude, 2.0) +
                pow(pointA.coordinate.longitude - pointB.coordinate.longitude, 2.0));
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
    self.userLocation = [locations lastObject];
}

-(void)fetchData {
    __weak typeof(self) weakSelf = self;
    void(^completion)(NSArray<Category *> *, NSError *) = ^void(NSArray<Category*> *categories, NSError *error){
        typeof(self) strongSelf = weakSelf;
        if(error == nil){
            if(strongSelf){
                strongSelf.categories = categories;
                [strongSelf.FiltersTableView reloadData];
            }
        } else{
            NSLog(@"%@", error);
        }
    };
    fetchAllCategories(completion);
    PFQuery *query = [PFQuery queryWithClassName: @"Listing"];
    [query orderByDescending:@"createdAt"];
    [query includeKey:@"availabilities"];
    [query includeKey:@"reservations"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf){
            strongSelf.tableData = objects;
            strongSelf.filteredListings = (NSArray<Listing *> *)objects;
            [strongSelf.listingsTableView reloadData];
        } else{
            NSLog(@"END: Error in querying listings");
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(tableView == self.listingsTableView){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"DetailsViewNavigationController"];
        [self presentViewController:navigationVC animated:YES completion:nil];
        DetailsViewController *detailsVC = (DetailsViewController *) [storyboard instantiateViewControllerWithIdentifier:@"DetailsViewController"];
        detailsVC.listing = (Listing *) self.filteredListings[indexPath.row];
        [navigationVC pushViewController:detailsVC animated:YES];
    }
}

- (IBAction)didTapFilters:(id)sender {
    [self.FiltersTableView setHidden:![self.FiltersTableView isHidden]];
}

- (IBAction)didSearchPolygon:(id)sender {
    void(^completion)(NSArray<Listing *> *, NSError *error) = ^void(NSArray<Listing *> *listings, NSError *error){
        if(error == nil){
            NSLog(@"END: Successfully searched for listings in polygon");
            for(int i = 0; i < listings.count; i ++){
                Listing *listing = listings[i];
                MKPointAnnotation *pa = [[MKPointAnnotation alloc] init];
                pa.coordinate = CLLocationCoordinate2DMake(listing.geoPoint.latitude, listing.geoPoint.longitude);
                pa.title = listing.title;
                [self.mapView addAnnotation:pa];
            }
        } else{
            NSLog(@"END: Error in didSearchPolygon");
        }
    };
    fetchListingsWithCoordinates(self.mapPoints, completion);
}

- (IBAction)didRemovePoints:(id)sender {
    [self.mapPoints removeAllObjects];
    NSArray *annotations = self.mapView.annotations;
    [self.mapView removeAnnotations:annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
}

- (IBAction)didChangeListing:(id)sender {
    if([self.mapView isHidden]){
        [self.mapView setHidden:NO];
        [self.removePointsButton setHidden:NO];
        [self.searchPolygonButton setHidden:NO];
        [self.listingTypeButton.titleLabel setText:@"List"];
        [self.FiltersButton setHidden:YES];
        [self.FiltersTableView setHidden:YES];
    } else{
        [self.mapView setHidden:YES];
        [self.removePointsButton setHidden:YES];
        [self.searchPolygonButton setHidden:YES];
        [self.listingTypeButton.titleLabel setText:@"Map"];
        [self.FiltersButton setHidden: NO];
    }
}

- (IBAction)didLogOut:(id)sender {
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
        if(error){
            NSLog(@"Error in didLogout");
        }
    }];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SignInViewController *signInViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
    SceneDelegate *sceneDelegate = (SceneDelegate * ) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
    sceneDelegate.window.rootViewController = signInViewController;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if(tableView == self.listingsTableView){
        ListingTableViewCell *cell = [self.listingsTableView dequeueReusableCellWithIdentifier:@"ListingTableViewCell"];
        cell.listing = self.filteredListings[indexPath.row];
        [cell initializeCell];
        return cell;
    } else{ // filters table view
        FiltersTableViewCell *cell = [self.FiltersTableView dequeueReusableCellWithIdentifier:@"FiltersTableViewCell"];
        cell.category = self.categories[indexPath.row];
        cell.delegate = self;
        [cell initializeCell];
        return cell;
    }
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(tableView == self.listingsTableView){
        return self.filteredListings.count;
    } else{ // filters table view
        return self.categories.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)didSelectCategory:(nonnull NSString *)categoryId {
    Filter *newFilter = [Filter new];
    newFilter.userId = [[PFUser currentUser] objectId];
    newFilter.categoryId = categoryId;
    [APIManager fetchNearestCity:self.userLocation completion:^(NSString * _Nonnull city, NSError * _Nonnull error) {
        if(error){
            NSLog(@"END: Error in fetching nearest city for current user");
        } else{
            newFilter.location = city;
            [newFilter saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if(error){
                    NSLog(@"END: Error in saving Filter");
                } else{
                    NSLog(@"END: Successfully saved Filter");
                }
            }];
        }
    }];
    NSMutableArray<Listing *> *result = [NSMutableArray<Listing *> new];
    [self.selectedCategories addObject:categoryId];
    for(Listing * listing in self.tableData){
        if([self.selectedCategories containsObject:listing.categoryId]){
            [result addObject:listing];
        }
    }
    self.filteredListings = [result copy];
    [self.listingsTableView reloadData];
}

- (void)didUnselectCategory:(nonnull NSString *)categoryId {
    NSMutableArray<Listing *> *result = [NSMutableArray<Listing *> new];
    [self.selectedCategories removeObject:categoryId];
    for(Listing * listing in self.tableData){
        if([self.selectedCategories containsObject:listing.categoryId]){
            [result addObject:listing];
        }
    }
    self.filteredListings = [result copy];
    if(self.selectedCategories.count == 0){
        self.filteredListings = self.tableData;
    }
    [self.listingsTableView reloadData];
}

@end
