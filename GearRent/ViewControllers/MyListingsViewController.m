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
#import "Item.h"
#import "Reservation.h"
#import "TimeInterval.h"

@interface MyListingsViewController ()<UITableViewDelegate, UITableViewDataSource, ListingTableViewCellDelegate>

@property (strong, nonatomic) IBOutlet UITableView *listingsTableView;
@property (strong, nonatomic) NSArray *tableData;

- (IBAction)didCreateListing:(id)sender;

@end

@implementation MyListingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.listingsTableView.delegate = self;
    self.listingsTableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated {
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
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error){
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf){
            strongSelf.tableData = objects;
            [strongSelf.listingsTableView reloadData];
        } else{
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

- (void)didEditListing:(Item *)listing {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"CreateListingNavigationController"];
    CreateListingViewController *createVC = (CreateListingViewController *) navigationVC.topViewController;
    createVC.listing = listing;
    [self presentViewController:navigationVC animated:YES completion:nil];
}

- (void)didViewReservations:(Item *)listing {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"ViewReservationsNavigationController"];
    ListingReservationsViewController *reservationsVC = (ListingReservationsViewController *) navigationVC.topViewController;
    reservationsVC.listing = listing;
    [self presentViewController: navigationVC animated: YES completion:nil];
}

@end
