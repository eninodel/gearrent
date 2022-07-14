//
//  GettingStartedViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/5/22.
//

#import "GettingStartedViewController.h"
#import "VerifyEmailViewController.h"
#import "../../Delegates/SceneDelegate.h"
#import "../../Delegates/AppDelegate.h"
#import "Parse/Parse.h"

@interface GettingStartedViewController ()
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
- (IBAction)didSignUp:(id)sender;
- (IBAction)didSignIn:(id)sender;


@end

@implementation GettingStartedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) registerUser{
    PFUser *newUser = [PFUser user];
    newUser.username = self.usernameTextField.text;
    newUser.email = self.emailTextField.text;
    newUser.password = self.passwordTextField.text;
    newUser[@"name"] = self.nameTextField.text;
    newUser[@"userEmail"] = self.emailTextField.text;
    [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
        } else {
            NSLog(@"User registered successfully");
            UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            self.view.window.rootViewController = [story instantiateViewControllerWithIdentifier:@"VerifyEmailViewController"];
        }
    }];
}

- (IBAction)didSignIn:(id)sender {
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.view.window.rootViewController = [story instantiateViewControllerWithIdentifier:@"SignInViewController"];
}

- (IBAction)didSignUp:(id)sender {
    [self registerUser];
}

@end
