//
//  ListingReservationsViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/14/22.
//

#import "ListingReservationsViewController.h"
#import "Item.h"
#import "Reservation.h"
#import "TimeInterval.h"
#import "Parse/Parse.h"
#import "ReservationTableViewCell.h"

@interface ListingReservationsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *reservations;

- (IBAction)didTapBack:(id)sender;

@end

@implementation ListingReservationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.reservations = [[NSArray alloc] init];
    PFQuery *query = [PFQuery queryWithClassName:@"Reservation"];
    [query includeKey:@"dates"];
    [query whereKey:@"itemId" equalTo:[self.listing objectId] ];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error == nil){
            self.reservations = objects;
            [self.tableView reloadData];
        }else{
            NSLog(@"END: Error fetching reservation dates");
        }
    }];
}

- (IBAction)didTapBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ReservationTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ReservationTableViewCell"];
    cell.reservation = self.reservations[indexPath.row];
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
