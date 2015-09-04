//
//  DefaultSettingsViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 6/19/14.
//
//

#import <UIKit/UIKit.h>

#import <Parse/PFLogInViewController.h>
#import <Parse/PFSignUpViewController.h>

#import "myLogInViewController.h"
#import "mySignUpViewController.h"
#import "verificationViewController.h"

@interface DefaultSettingsViewController : UIViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) myLogInViewController *myLogIn;

@property (weak, nonatomic) IBOutlet UILabel *logo;
@property (strong, nonatomic) UILabel *statusLabel;

// public methods
- (void)launchLogIn;

@end
