//
//  inboxTableViewController.h
//  echoprint
//
//  Created by Samvit Jain on 6/14/14.
//
//

#import <UIKit/UIKit.h>

#import "echoprint_Prefix.pch"

@interface inboxTableViewController : UITableViewController <NSURLConnectionDataDelegate>

//@property (nonatomic, strong) NSMutableData *connectionData;
//@property (nonatomic, strong) NSArray *messageArray;

@property (nonatomic, strong) NSMutableArray *links; // of Links
@property (nonatomic, strong) NSMutableArray *contacts; // of NSMutArrays
@property (nonatomic, strong) NSMutableArray *loaded; // of encased BOOLs

@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end
