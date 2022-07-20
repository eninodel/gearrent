//
//  BookingsViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/15/22.
//

#import "BookingsViewController.h"
#import "Parse/Parse.h"
#import "BookingTableViewCell.h"
#import "Reservation.h"

@interface BookingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *reservations;

@end

@implementation BookingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self fetchData];
}

- (void)fetchData {
    PFQuery *query = [PFQuery queryWithClassName:@"Reservation"];
    [query whereKey:@"leaseeId" equalTo:[[PFUser currentUser] objectId]];
    [query includeKey:@"dates"];
    __weak typeof(self) weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf){
            strongSelf.reservations = objects;
            [strongSelf.tableView reloadData];
        } else{
            NSLog(@"END: Error fetching reservations for user");
        }
    }];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    BookingTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"BookingTableViewCell"];
    cell.reservation = (Reservation *)self.reservations[indexPath.row];
    [cell initializeCell];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.reservations.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

@end
