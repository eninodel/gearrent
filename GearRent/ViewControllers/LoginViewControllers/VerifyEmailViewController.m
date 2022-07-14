//
//  VerifyEmailViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/5/22.
//

#import "VerifyEmailViewController.h"
#import "Parse/Parse.h"

@interface VerifyEmailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *verifiedLabel;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation VerifyEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0
             target:self
            selector:@selector(checkEmailVerified)
             userInfo:nil
             repeats:YES];
}

- (void)checkEmailVerified {
    PFUser *currentUser = [PFUser currentUser];
    
    [currentUser fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if(error == nil){
            if([object[@"emailVerified"] boolValue] != NO){
                NSLog(@"END: Verified Email Successfully");
                self.verifiedLabel.text = @"Current Status: Verified";
                [self.timer invalidate];
                self.timer = nil;
                UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                self.view.window.rootViewController = [story instantiateViewControllerWithIdentifier:@"MainTabBarController"];
            } else{
                NSLog(@"END: Email Not Verified");
            }
        }else{
            NSLog(@"END: Error in fetching user in VerifyEmailViewController");
        }
    }];
}

@end
