//
//  verificationViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/14/14.
//
//

#import <UIKit/UIKit.h>

#import <Parse/Parse.h>

@interface verificationViewController : UIViewController <UITextFieldDelegate, UIGestureRecognizerDelegate>

// UI elements
@property (weak, nonatomic) IBOutlet UIView *header;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) UITextField *mobileNumberTextField;
@property (strong, nonatomic) UITextField *codeTextField;

@property (strong, nonatomic) UILabel *codeVerificationLabel;       // "Please enter the code you receive"
@property (strong, nonatomic) UILabel *backLabel;                   // "Go back"

@property (weak, nonatomic) IBOutlet UIButton *verificationButton;  // Send code (via SMS)/ Verify code

@property (strong, nonatomic) UIView *verificationScreen;

// UI element states
@property (nonatomic) int backPressedCounter;

@end
