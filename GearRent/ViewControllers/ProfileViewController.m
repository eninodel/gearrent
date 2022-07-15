//
//  ProfileViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/6/22.
//

#import "ProfileViewController.h"
#import "Parse/Parse.h"
#import "UIImageView+AFNetworking.h"
#import "../ViewControllers/LoginViewControllers/SignInViewController.h"
#import "../Delegates/SceneDelegate.h"
#import "ProfileImagePickerViewController.h"

@interface ProfileViewController () <ProfileImagePickerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UIButton *paymentsUIButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationsUIButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsUIButton;
@property (weak, nonatomic) IBOutlet UIButton *logOutUIButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UILabel *tapToChangeLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIStackView *saveButtonsStackView;
@property (weak, nonatomic) IBOutlet UIButton *saveUIButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelUIButton;
@property (strong, nonatomic) UIImage *prevProfileImage;

- (IBAction)didLogOut:(id)sender;
- (IBAction)didEditProfile:(id)sender;
- (IBAction)didChangeProfileImage:(id)sender;
- (IBAction)didSaveProfile:(id)sender;
- (IBAction)didCancelEditingProfile:(id)sender;

@property (assign, nonatomic) Boolean *editing;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    PFUser *user =[PFUser currentUser];
    [self setEditingHidden:(Boolean *) false];
    self.emailLabel.text = user[@"userEmail"];
    self.usernameLabel.text = user.username;
    self.nameLabel.text = user[@"name"];
    double buttonBorderWidth = 1.0;
    double buttonCornerRadius = 5.0;
    struct CGColor *buttonBorderColor = UIColor.grayColor.CGColor;
    self.paymentsUIButton.layer.borderWidth = buttonBorderWidth;
    self.paymentsUIButton.layer.borderColor = buttonBorderColor;
    self.paymentsUIButton.layer.cornerRadius = buttonCornerRadius;
    self.notificationsUIButton.layer.borderWidth = buttonBorderWidth;
    self.notificationsUIButton.layer.borderColor = buttonBorderColor;
    self.notificationsUIButton.layer.cornerRadius = buttonCornerRadius;
    self.settingsUIButton.layer.borderWidth = buttonBorderWidth;
    self.settingsUIButton.layer.borderColor = buttonBorderColor;
    self.settingsUIButton.layer.cornerRadius = buttonCornerRadius;
    self.profileImageView.layer.cornerRadius = 50.0;
    self.profileImageView.layer.masksToBounds = true;
    PFQuery *query = [PFUser query];
    [query whereKey: @"objectId" equalTo:[user objectId]];
    [query includeKey:@"profileImage"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error == nil){
            PFUser *user = (PFUser*) objects[0];
            UIImage *defaultProfileImage = [UIImage imageNamed:@"DefaultProfileImage"];
            if(user[@"profileImage"] == nil){
                UIImage *defaultProfileImage = [UIImage imageNamed:@"DefaultProfileImage"];
                self.prevProfileImage = defaultProfileImage;
                [self.profileImageView setImage:defaultProfileImage];
            }else{
                PFFileObject *image = (PFFileObject *) user[@"profileImage"];
                NSURL *profileImageURL = [NSURL URLWithString: image.url];
                [self.profileImageView setImageWithURLRequest:[NSURLRequest requestWithURL:profileImageURL] placeholderImage:defaultProfileImage success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                    self.prevProfileImage = image;
                    [self.profileImageView setImage:image];
                } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                    NSLog(@"END: Error in setting profileImageView");
                }];
            }
        }else{
            NSLog(@"END: Error in fetching user in ProfileViewController");
        }
    }];
}

- (IBAction)didCancelEditingProfile:(id)sender {
    [self.profileImageView setImage:self.prevProfileImage];
    [self setEditingHidden:(Boolean *) false];
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

- (IBAction)didSaveProfile:(id)sender {
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"name"] = self.nameTextField.text;
    self.nameLabel.text = self.nameTextField.text;
    if(![currentUser[@"userEmail"] isEqualToString:self.emailTextField.text]){
        currentUser[@"userEmail"] = self.emailTextField.text;
        currentUser.email = self.emailTextField.text;
        self.emailLabel.text = self.emailTextField.text;
    }
    currentUser[@"profileImage"] = [self getPFFileFromImage:self.profileImageView.image];
    self.prevProfileImage = self.profileImageView.image;
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(error == nil){
            NSLog(@"Saved user successfully");
            [currentUser fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if(error == nil){
                    NSLog(@"END: Successfully saved user");
                }else{
                    NSLog(@"END: Error in saving user");
                }
            }];
        }else{
            NSLog(@"END: Error in saving user in didSaveProfile");
            NSLog(@"%@", error.description);
        }
    }];
    [self setEditingHidden:(Boolean *) false];
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

- (PFFileObject *)getPFFileFromImage:(UIImage * _Nullable)image {
    // check if image is not nil
    if (!image) {
        return nil;
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    // get image data and check if that is not nil
    if (!imageData) {
        return nil;
    }
    return [PFFileObject fileObjectWithName:@"image.png" data:imageData];
}

- (IBAction)didChangeProfileImage:(id)sender {
    if(!self.editing) {
        return;
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationVC = [storyboard instantiateViewControllerWithIdentifier:@"ProfileImagePickerNavigationController"];
    [self presentViewController:navigationVC animated:YES completion:nil];
    ProfileImagePickerViewController *profileImagePickerVC = (ProfileImagePickerViewController *) navigationVC.topViewController;
    profileImagePickerVC.delegate = self;
}

- (IBAction)didEditProfile:(id)sender {
    self.nameTextField.text = [PFUser currentUser][@"name"];
    self.emailTextField.text = [PFUser currentUser][@"userEmail"];
    [self setEditingHidden: (Boolean *) true];
}

- (void)setEditingHidden:(Boolean *)editing {
    self.editing = editing;
    self.paymentsUIButton.hidden = editing;
    self.notificationsUIButton.hidden = editing;
    self.settingsUIButton.hidden = editing;
    self.logOutUIButton.hidden = editing;
    self.nameTextField.hidden = !editing;
    self.emailTextField.hidden = !editing;
    self.tapToChangeLabel.hidden = !editing;
    self.saveButtonsStackView.hidden = !editing;
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

- (void)didPickProfileImage:(nonnull UIImage *)image {
    [self.profileImageView setImage:image];
}
@end
