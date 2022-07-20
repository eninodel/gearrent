//
//  SignInViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/5/22.
//

#import "SignInViewController.h"
#import "Parse/Parse.h"

@interface SignInViewController ()

@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)didSignUp:(id)sender;
- (IBAction)didSignIn:(id)sender;

@end

@implementation SignInViewController

- (void)signIn {
    NSLog(@"END: In signIn");
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser * user, NSError *  error) {
        if (error != nil) {
            NSLog(@"User log in failed: %@", error.localizedDescription);
        } else {
            NSLog(@"User logged in successfully");
            UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            self.view.window.rootViewController = [story instantiateViewControllerWithIdentifier:@"MainTabBarController"];
        }
    }];
}

- (IBAction)didSignIn:(id)sender {
    [self signIn];
}

- (IBAction)didSignUp:(id)sender {
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.view.window.rootViewController = [story instantiateViewControllerWithIdentifier:@"GettingStartedViewController"];
}

@end
