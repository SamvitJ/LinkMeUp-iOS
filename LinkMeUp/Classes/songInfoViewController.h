//
//  songInfoViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/10/14.
//
//

#import <UIKit/UIKit.h>

#import "contactsViewController.h"

#import "Constants.h"
#import "Data.h"

@interface songInfoViewController : UIViewController <UITextViewDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// VC state
@property (nonatomic) BOOL isForwarding;

// UI elements
@property (weak, nonatomic) IBOutlet UIView *header;
@property (weak, nonatomic) IBOutlet UIButton *sendToButton;

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *artistLabel;
@property (strong, nonatomic) UILabel *channelLabel;
@property (strong, nonatomic) UILabel *viewsLabel;

@property (strong, nonatomic) UIImageView *artImageView;
@property (strong, nonatomic) UITextView *annotationView;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

// UI element states
@property (nonatomic, strong) UIColor *backgroundColor;

// associated VCs
@property (nonatomic, strong) contactsViewController *contactsVC;

@end
