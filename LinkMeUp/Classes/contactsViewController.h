//
//  contactsViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 6/12/14.
//
//

#import <UIKit/UIKit.h>

#import "LinkMeUpAppDelegate.h"

#import "Link.h"
#import "Data.h"

@interface contactsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// VC state
@property (nonatomic) BOOL isForwarding;

// UI elements
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *sendSong;
@property (weak, nonatomic) IBOutlet UIView *header;

// link
@property (nonatomic, strong) Link *myLink;

@end
