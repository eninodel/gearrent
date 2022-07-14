//
//  ProfileImagePickerViewController.h
//  GearRent
//
//  Created by Edwin Delgado on 7/6/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ProfileImagePickerViewControllerDelegate <NSObject>

- (void) didPickProfileImage: (UIImage *) image;

@end

@interface ProfileImagePickerViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) id<ProfileImagePickerViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
