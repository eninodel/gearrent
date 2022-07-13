//
//  MyListingsViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/7/22.
//

#import "MyListingsViewController.h"
#import "Parse/Parse.h"
#import "ListingTableViewCell.h"
#import "../Models/Item.h"
#import "../Models/Reservation.h"
#import "../Models/TimeInterval.h"

@interface MyListingsViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *listingsTableView;
@property (strong, nonatomic) NSArray *tableData;
- (IBAction)didCreateListing:(id)sender;

@end

@implementation MyListingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.listingsTableView.delegate = self;
    self.listingsTableView.dataSource = self;
    PFQuery *query = [PFQuery queryWithClassName:@"Listing"];
    [query whereKey:@"ownerId" equalTo:[[PFUser currentUser] objectId]];
    [query orderByDescending:@"createdAt"];
    [query includeKey:@"availabilities"];
    [query includeKey:@"reservations"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error){
        if(error == nil){
            self.tableData = objects;
            [self.listingsTableView reloadData];
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
    ListingTableViewCell *cell = [self.listingsTableView dequeueReusableCellWithIdentifier:@"ListingTableViewCell"];
    cell.listing = self.tableData[indexPath.row];
    cell.findStatus = YES;
    [cell initializeCell];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count;
}

@end
