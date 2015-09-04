//
//  messageViewController.h
//  echoprint
//
//  Created by Samvit Jain on 6/12/14.
//
//

#import <UIKit/UIKit.h>

#import "contactsViewController.h"

@interface messageViewController : UIViewController <UITextViewDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// UI labels
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;

// use UITextField instead?
@property (weak, nonatomic) IBOutlet UITextView *textBox;

@property (strong, nonatomic) contactsViewController *cvc;

- (IBAction)dismissKeyboardOnTap:(id)sender;

@end
