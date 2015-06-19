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

@interface searchViewController : UIViewController <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// autocomplete results
@property (strong, nonatomic) NSMutableArray *searchResults;

// UI elements
@property (weak, nonatomic) IBOutlet UIView *header;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) UILabel *captionTitle;
@property (strong, nonatomic) UILabel *captionText;

@property (strong, nonatomic) UIView *AIView;
@property (strong, nonatomic) UIActivityIndicatorView *searchDisplayAI;

@property (strong, nonatomic) UIImageView *searchIconView;

@property (nonatomic) BOOL currentlyShifted;

//@property (strong, nonatomic) UISearchBar *searchBar;
//@property (strong, nonatomic) UISearchDisplayController *searchDisplay;

// public methods
- (void)clearAndInitialize;

@end
