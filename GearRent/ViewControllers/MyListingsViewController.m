//
//  MyListingsViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/7/22.
//

#import "MyListingsViewController.h"

@interface MyListingsViewController ()
- (IBAction)didCreateListing:(id)sender;

@end

@implementation MyListingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (IBAction)didCreateListing:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"CreateListingNavigationController"];
    [self presentViewController:navigationVC animated:YES completion:nil];
}
@end
