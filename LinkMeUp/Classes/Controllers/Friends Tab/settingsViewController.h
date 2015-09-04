//
//  settingsViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 8/16/14.
//
//

#import <UIKit/UIKit.h>

#import "Data.h"

@interface settingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// UI elements
@property (weak, nonatomic) IBOutlet UIView *header;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
