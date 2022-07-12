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

@interface GearForRentViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) NSArray *tableData;
@property (weak, nonatomic) IBOutlet UITableView *listingsTableView;

- (IBAction)didLogOut:(id)sender;

@end

@implementation GearForRentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.listingsTableView.delegate = self;
    self.listingsTableView.dataSource = self;
    PFQuery *query = [PFQuery queryWithClassName: @"Listing"];
    [query orderByDescending:@"createdAt"];
    [query includeKey:@"availabilities"];
    [query includeKey:@"reservations"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error == nil){
            self.tableData = objects;
            [self.listingsTableView reloadData];
        } else{
            NSLog(@"END: Error in querying listings");
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"DetailsViewNavigationController"];
    [self presentViewController:navigationVC animated:YES completion:nil];
    DetailsViewController *detailsVC = (DetailsViewController *) [storyboard instantiateViewControllerWithIdentifier:@"DetailsViewController"];
    detailsVC.listing = (Item *) self.tableData[indexPath.row];
    [navigationVC pushViewController:detailsVC animated:YES];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

@end
