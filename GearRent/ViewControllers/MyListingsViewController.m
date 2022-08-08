//
//  MyListingsViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/7/22.
//

#import "MyListingsViewController.h"
#import "Parse/Parse.h"
#import "ListingTableViewCell.h"
#import "CreateListingViewController.h"
#import "ListingReservationsViewController.h"
#import "Listing.h"
#import "Reservation.h"
#import "TimeInterval.h"

@interface MyListingsViewController ()<UITableViewDelegate, UITableViewDataSource, ListingTableViewCellDelegate>

@property (strong, nonatomic) IBOutlet UITableView *listingsTableView;
@property (strong, nonatomic) NSArray *tableData;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

- (IBAction)didCreateListing:(id)sender;

@end

@implementation MyListingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.listingsTableView.delegate = self;
    self.listingsTableView.dataSource = self;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchData) forControlEvents:UIControlEventValueChanged];
    [self.listingsTableView addSubview:self.refreshControl];
    [self.refreshControl beginRefreshing];
    [self fetchData];
}

-(void)fetchData {
    PFQuery *query = [PFQuery queryWithClassName:@"Listing"];
    [query whereKey:@"ownerId" equalTo:[[PFUser currentUser] objectId]];
    [query orderByDescending:@"createdAt"];
    [query includeKey:@"availabilities"];
    [query includeKey:@"reservations"];
    [query includeKey:@"geoPoint"];
    __weak typeof(self) weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf) {
            strongSelf.tableData = objects;
            [strongSelf.refreshControl endRefreshing];
            [strongSelf.listingsTableView reloadData];
        } else {
            NSLog(@"END: Error in querying listings");
        }
    }];
}

- (IBAction)didCreateListing:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"CreateListingNavigationController"];
    [self presentViewController:navigationVC animated:YES completion:nil];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ListingTableViewCell *cell = [self.listingsTableView dequeueReusableCellWithIdentifier:@"MyListingTableViewCell"];
    cell.listing = self.tableData[indexPath.row];
    cell.findStatus = YES;
    [cell initializeCell];
    cell.delegate = self;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ListingTableViewCell *cell = (ListingTableViewCell *) [self.listingsTableView cellForRowAtIndexPath:indexPath];
    [cell displayOptions];
}

- (void)didEditListing:(Listing *)listing {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"CreateListingNavigationController"];
    CreateListingViewController *createVC = (CreateListingViewController *) navigationVC.topViewController;
    createVC.listing = listing;
    [self presentViewController:navigationVC animated:YES completion:nil];
}

- (void)didViewReservations:(Listing *)listing {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"ViewReservationsNavigationController"];
    ListingReservationsViewController *reservationsVC = (ListingReservationsViewController *) navigationVC.topViewController;
    reservationsVC.listing = listing;
    [self presentViewController:navigationVC animated:YES completion:nil];
}

@end
