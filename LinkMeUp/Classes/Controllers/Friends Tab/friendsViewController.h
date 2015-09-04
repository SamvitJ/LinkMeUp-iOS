//
//  friendsViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/2/14.
//
//

#import <UIKit/UIKit.h>

#import "LinkMeUpAppDelegate.h"

#import "Data.h"

@interface friendsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// UI elements
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *mySearchBar;

@property (nonatomic, strong) NSMutableArray *requestButtons;       // UIButton
@property (nonatomic, strong) NSMutableArray *suggestionButtons;    // UIButton

@property (strong, nonatomic) UIButton *facebookButton;
@property (strong, nonatomic) UILabel *facebookLabel;

// local data
@property (nonatomic, strong) NSMutableArray *allContacts;          // PFUser - concatenation of all contact arrays
@property (nonatomic, strong) NSMutableArray *searchResults;        // PFUser - temp container of search results

// friend requests resulting from username searches
@property (nonatomic, strong) PFUser *lastSearch;
@property (nonatomic, strong) NSMutableArray *userSearchButtons;    // UIButton
@property (nonatomic, strong) NSMutableArray *userSearchContacts;   // PFUser

// status
@property (nonatomic) BOOL receivedPush;
// @property (nonatomic) BOOL showFriendSuggestions;

@end
