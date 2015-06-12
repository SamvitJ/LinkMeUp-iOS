//
//  connectWithFriendsViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 12/13/14.
//
//

#import <UIKit/UIKit.h>

#import <AddressBook/AddressBook.h>

#import "Data.h"

@interface findContactsViewController : UIViewController <UIGestureRecognizerDelegate, UIAlertViewDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// UI elements
@property (weak, nonatomic) IBOutlet UILabel *lastLine;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;

@property (nonatomic, strong) UILabel *skipLabel;                   // Skip link with FB
@property (nonatomic, strong) UIImageView *imageView;

@end
