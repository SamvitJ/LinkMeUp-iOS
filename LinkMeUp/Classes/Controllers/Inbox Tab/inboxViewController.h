//
//  inboxViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/2/14.
//
//

#import <UIKit/UIKit.h>

#import "LinkMeUpAppDelegate.h"

#import "Data.h"
#import "Constants.h"

@interface inboxViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// status
@property (nonatomic) BOOL sentNewLink;
@property (nonatomic) BOOL receivedPush;
@property (nonatomic) InboxSegments selectedSegment;

// UI elements
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segControl;

@end
