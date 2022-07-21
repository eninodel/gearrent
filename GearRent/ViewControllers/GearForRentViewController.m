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

@interface GearForRentViewController ()<UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) NSArray *tableData;
@property (strong, nonatomic) IBOutlet UITableView *listingsTableView;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UIButton *listingTypeButton;

- (IBAction)didLogOut:(id)sender;
- (IBAction)didChangeListing:(id)sender;

@end

@implementation GearForRentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.listingsTableView.delegate = self;
    self.listingsTableView.dataSource = self;
    self.mapView.hidden = YES;
    self.listingTypeButton.titleLabel.text = @"Map";
    self.mapView.delegate = self;
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.distanceFilter = 200;
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)viewWillAppear:(BOOL)animated {
    [self fetchData];
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

- (IBAction)didChangeListing:(id)sender {
    if([self.mapView isHidden]){
        [self.mapView setHidden:NO];
        [self.listingTypeButton.titleLabel setText:@"List"];
    } else{
        [self.mapView setHidden:YES];
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
