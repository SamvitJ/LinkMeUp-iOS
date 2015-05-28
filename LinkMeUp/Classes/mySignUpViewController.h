//
//  mySignUpViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/6/14.
//
//

#import <Parse/Parse.h>

#import "verificationViewController.h"

@interface mySignUpViewController : PFSignUpViewController <UIGestureRecognizerDelegate>

@property (nonatomic, strong) verificationViewController *verificationVC;

// UI elements
@property (nonatomic, strong) UILabel *legalLabel;

@end
