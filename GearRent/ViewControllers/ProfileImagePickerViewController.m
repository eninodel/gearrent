//
//  ProfileImagePickerViewController.m
//  GearRent
//
//  Created by Edwin Delgado on 7/6/22.
//

#import "ProfileImagePickerViewController.h"

@interface ProfileImagePickerViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *profileUIImageView;

- (IBAction)didOpenGallery:(id)sender;
- (IBAction)didOpenCamera:(id)sender;
- (IBAction)didSave:(id)sender;
- (IBAction)didCancel:(id)sender;

@end

@implementation ProfileImagePickerViewController

- (IBAction)didOpenGallery:(id)sender {
    [self displayGallery];
}

- (IBAction)didCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didSave:(id)sender {
    [self.delegate didPickProfileImage: self.profileUIImageView.image];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didOpenCamera:(id)sender {
    [self displayCamera];
}

- (void)displayCamera {
    UIImagePickerController *imagePickerVC = [UIImagePickerController new];
    imagePickerVC.delegate = self;
    imagePickerVC.allowsEditing = YES;
    // The Xcode simulator does not support taking pictures, so let's first check that the camera is indeed supported on the device before trying to present it.
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else {
        NSLog(@"Camera 🚫 available so we will use photo library instead");
        imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [self presentViewController:imagePickerVC animated:YES completion:nil];
}

-(void)displayGallery {
    UIImagePickerController *imagePickerVC = [UIImagePickerController new];
    imagePickerVC.delegate = self;
    imagePickerVC.allowsEditing = YES;
    imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePickerVC animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    if([editedImage isEqual:nil]) {
        [self.profileUIImageView setImage:originalImage];
    } else{
        [self.profileUIImageView setImage:editedImage];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
