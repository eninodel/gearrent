//
//  BookingsViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/15/22.
//

#import "BookingsViewController.h"
#import "Parse/Parse.h"
#import "ReservationTableViewCell.h"
#import "../Models/Reservation.h"

@interface BookingsViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *reservations;
@end

@implementation BookingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    PFQuery *query = [PFQuery queryWithClassName:@"Reservation"];
    [query whereKey:@"leaseeId" equalTo:[[PFUser currentUser] objectId]];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error == nil){
            self.reservations = objects;
            [self.tableView reloadData];
        } else{
            NSLog(@"END: Error fetching reservations for user");
        }
    }];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ReservationTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ReservationTableViewCell"];
    cell.reservation = (Reservation *)self.reservations[indexPath.row];
    [cell initializeCell];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.reservations.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


@end
