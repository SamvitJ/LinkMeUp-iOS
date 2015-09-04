//
//  sentLinkViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/22/14.
//
//

#import "linkViewController.h"

@interface sentLinkViewController : linkViewController

// message threads for all recipients
@property (nonatomic, strong) NSMutableArray *receiversData;
@property (nonatomic, strong) NSMutableArray *sortedData;

// UI elements
@property (strong, nonatomic) UIToolbar *toolbar;

// public methods
- (void)setData;

@end
