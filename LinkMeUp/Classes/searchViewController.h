//
//  searchViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 8/4/14.
//
//

#import <UIKit/UIKit.h>

#import "Data.h"
#import "Constants.h"

@interface searchViewController : UIViewController <UITextFieldDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// autocomplete results
@property (strong, nonatomic) NSMutableArray *searchResults;

// UI elements
@property (weak, nonatomic) IBOutlet UIButton *sendVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *sendSongButton;

@property (strong, nonatomic) UILabel *videoPromptLabel;
@property (strong, nonatomic) UILabel *songPromptLabel;

@property (strong, nonatomic) UITextField *titleField;
@property (strong, nonatomic) UITextField *artistField;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

//@property (strong, nonatomic) UISearchBar *searchBar;
//@property (strong, nonatomic) UISearchDisplayController *searchDisplay;

// UI state
@property (nonatomic) MessengerOptions selectedState;

// public methods
- (void)clearAndInitialize;

@end
