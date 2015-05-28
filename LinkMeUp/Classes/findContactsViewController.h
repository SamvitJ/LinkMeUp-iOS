//
//  connectWithFriendsViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 12/13/14.
//
//

#import <UIKit/UIKit.h>

#import <AddressBook/AddressBook.h>

@interface findContactsViewController : UIViewController <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (strong, nonatomic) UILabel *skipLabel;                   // Skip link with FB

@end
