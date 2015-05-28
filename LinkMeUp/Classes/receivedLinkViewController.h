//
//  receivedLinkViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/22/14.
//
//

#import "linkViewController.h"

@interface receivedLinkViewController : linkViewController

// message data for me
@property (nonatomic, strong) NSMutableDictionary *receiverData;
@property (nonatomic, strong) NSArray *messages;

// UI elements
@property (strong, nonatomic) UIToolbar *toolbar;

// public methods
- (void)setData;

@end
