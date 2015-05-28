//
//  replyViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/20/14.
//
//

#import <UIKit/UIKit.h>

#import "LinkMeUpAppDelegate.h"

#import "Data.h"
#import "Link.h"
#import "Constants.h"

@interface replyViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// selected link
@property (nonatomic) BOOL isLinkSender; // YES if I sent the link
@property (nonatomic, strong) NSString *contactId; // objectId of message recipient

// messages data
@property (nonatomic, strong) NSMutableDictionary *receiverData;
@property (nonatomic, strong) NSMutableArray *messages;

// UI elements
@property (weak, nonatomic) IBOutlet UIView *header;
@property (weak, nonatomic) IBOutlet UILabel *headerTitle;
@property (weak, nonatomic) IBOutlet UITableView *replyTable;
@property (strong, nonatomic) UITextView *currentMessage;

@end
