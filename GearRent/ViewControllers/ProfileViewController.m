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

@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *emailLabel;
@property (strong, nonatomic) IBOutlet UIButton *paymentsUIButton;
@property (strong, nonatomic) IBOutlet UIButton *notificationsUIButton;
@property (strong, nonatomic) IBOutlet UIButton *settingsUIButton;
@property (strong, nonatomic) IBOutlet UIButton *logOutUIButton;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UILabel *tapToChangeLabel;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UIStackView *saveButtonsStackView;
@property (strong, nonatomic) IBOutlet UIButton *saveUIButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelUIButton;
@property (strong, nonatomic) UIImage *prevProfileImage;

- (IBAction)didLogOut:(id)sender;
- (IBAction)didEditProfile:(id)sender;
- (IBAction)didChangeProfileImage:(id)sender;
- (IBAction)didSaveProfile:(id)sender;
- (IBAction)didCancelEditingProfile:(id)sender;

@property (assign, nonatomic) BOOL editing;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    PFUser *user =[PFUser currentUser];
    [self setEditingHidden:NO];
    self.emailLabel.text = user[@"userEmail"];
    self.usernameLabel.text = user.username;
    self.nameLabel.text = user[@"name"];
    self.profileImageView.layer.cornerRadius = 50.0;
    self.profileImageView.layer.masksToBounds = true;
    PFQuery *query = [PFUser query];
    [query whereKey: @"objectId" equalTo:[user objectId]];
    [query includeKey:@"profileImage"];
    __weak typeof(self) weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        typeof(self) strongSelf = weakSelf;
        if(error == nil && strongSelf) {
            PFUser *user = (PFUser*) objects[0];
            UIImage *defaultProfileImage = [UIImage imageNamed:@"DefaultProfileImage"];
            if(user[@"profileImage"] == nil) {
                UIImage *defaultProfileImage = [UIImage imageNamed:@"DefaultProfileImage"];
                strongSelf.prevProfileImage = defaultProfileImage;
                [strongSelf.profileImageView setImage:defaultProfileImage];
            }else {
                PFFileObject *image = (PFFileObject *) user[@"profileImage"];
                NSURL *profileImageURL = [NSURL URLWithString: image.url];
                [strongSelf.profileImageView setImageWithURLRequest:[NSURLRequest requestWithURL:profileImageURL] placeholderImage:defaultProfileImage success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                    typeof (self) strongSelf = weakSelf;
                    if(strongSelf) {
                        strongSelf.prevProfileImage = image;
                        [strongSelf.profileImageView setImage:image];
                    }
                } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                    NSLog(@"END: Error in setting profileImageView");
                }];
            }
        }else {
            NSLog(@"END: Error in fetching user in ProfileViewController");
        }
    }];
}

- (IBAction)didCancelEditingProfile:(id)sender {
    [self.profileImageView setImage:self.prevProfileImage];
    [self setEditingHidden:NO];
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
        }else {
            NSLog(@"END: Error in saving user in didSaveProfile");
            NSLog(@"%@", error.description);
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ Error", error.domain]
                                           message:@"Could not save profile. Please try again"
                                           preferredStyle:UIAlertControllerStyleAlert];
             
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
               handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
    [self setEditingHidden: NO];
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
    [self setEditingHidden:YES];
}

- (void)setEditingHidden:(BOOL)editing {
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
