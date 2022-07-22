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

@interface GearForRentViewController ()<UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) NSArray *tableData;
@property (strong, nonatomic) IBOutlet UITableView *listingsTableView;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UIButton *listingTypeButton;
@property (strong, nonatomic) NSMutableArray<CLLocation *> *mapPoints;
@property (strong, nonatomic) IBOutlet UIButton *removePointsButton;
@property (strong, nonatomic) IBOutlet UIButton *searchPolygonButton;

- (IBAction)didLogOut:(id)sender;
- (IBAction)didChangeListing:(id)sender;
- (IBAction)didRemovePoints:(id)sender;
- (IBAction)didSearchPolygon:(id)sender;

@end

@implementation GearForRentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.mapPoints = [NSMutableArray<CLLocation *> new];
    self.listingsTableView.delegate = self;
    self.listingsTableView.dataSource = self;
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

- (void)renderMapPoints{
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
}

-(void)fetchData {
    PFQuery *query = [PFQuery queryWithClassName: @"Listing"];
    [query orderByDescending:@"createdAt"];
    [query includeKey:@"availabilities"];
    [query includeKey:@"reservations"];
    __weak typeof(self) weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf){
            strongSelf.tableData = objects;
            [strongSelf.listingsTableView reloadData];
        } else{
            NSLog(@"END: Error in querying listings");
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"DetailsViewNavigationController"];
    [self presentViewController:navigationVC animated:YES completion:nil];
    DetailsViewController *detailsVC = (DetailsViewController *) [storyboard instantiateViewControllerWithIdentifier:@"DetailsViewController"];
    detailsVC.listing = (Item *) self.tableData[indexPath.row];
    [navigationVC pushViewController:detailsVC animated:YES];
}

- (IBAction)didSearchPolygon:(id)sender {
    void(^completion)(NSArray<Item *> *, NSError *error) = ^void(NSArray<Item *> *listings, NSError *error){
        if(error == nil){
            NSLog(@"%@", listings);
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
    } else{
        [self.mapView setHidden:YES];
        [self.removePointsButton setHidden:YES];
        [self.searchPolygonButton setHidden:YES];
        [self.listingTypeButton.titleLabel setText:@"Map"];
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
    ListingTableViewCell *cell = [self.listingsTableView dequeueReusableCellWithIdentifier:@"ListingTableViewCell"];
    cell.listing = self.tableData[indexPath.row];
    [cell initializeCell];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

@end
