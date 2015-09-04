//
//  searchResultsViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 8/1/14.
//
//

#import <UIKit/UIKit.h>

#import "Data.h"
#import "Constants.h"

#import "contactsViewController.h"

@interface searchResultsViewController : UIViewController <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// search results data
@property (nonatomic, strong) NSMutableArray *VEVOvideos;  // NSDictionary
@property (nonatomic, strong) NSMutableArray *videos;      // NSDictionary

// UI elements
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *sendToButton;
@property (weak, nonatomic) IBOutlet UIView *header;

@property (nonatomic, strong) NSMutableArray *imageViews;           // UIImageView
@property (nonatomic, strong) NSMutableArray *activityIndicators;   // UIActivityIndicator
@property (nonatomic, strong) NSMutableArray *webViews;             // UIWebView

@property (nonatomic, strong) NSTimer *webViewStatusTimer;

@property (strong, nonatomic) UITextView *annotationView;

@property (strong, nonatomic) UIActivityIndicatorView *mainActivityIndicator;

// UI element states
@property (nonatomic) int selectedCell;
//@property (nonatomic, strong) UIColor *backgroundColor;

// associated VCs
@property (nonatomic, strong) contactsViewController *contactsVC;

@end
