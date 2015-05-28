//
//  optionsViewController.h
//  echoprint
//
//  Created by Samvit Jain on 7/10/14.
//
//

#import <UIKit/UIKit.h>

#import "songInfoViewController.h"

#import "Constants.h"
#import "Data.h"

@interface optionsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// text fields
@property (strong, nonatomic) UITextField *titleField;
@property (strong, nonatomic) UITextField *artistField;

// cell labels
@property (strong, nonatomic) UILabel *userEnterLabel;

// UI elements
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;

// UI element states
@property (nonatomic) MessengerOptions selectedCell;

// associated VCs
@property (strong, nonatomic) songInfoViewController *songInfoVC;

@end
