//
//  youtubeSearchViewController.h
//  echoprint
//
//  Created by Samvit Jain on 8/1/14.
//
//

#import <UIKit/UIKit.h>

#import "Data.h"
#import "Constants.h"

@interface youtubeSearchViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// autocomplete results
@property (strong, nonatomic) NSMutableArray *searchResults;

// UI elements
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end
