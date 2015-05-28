//
//  friendsTableViewController.h
//  echoprint
//
//  Created by Samvit Jain on 6/27/14.
//
//

#import <UIKit/UIKit.h>

@interface friendsTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *friendRequests; // of FriendRequest*
@property (nonatomic, strong) NSMutableArray *requestSenders; // of PFUser*
@property (nonatomic, strong) NSMutableArray *requestButtons;

@property (nonatomic, strong) NSMutableArray *myFriends; // of PFUser*

@property (nonatomic, strong) NSMutableArray *FBFriendSuggestions; // of NSDictionary<FBGraphUser>*
@property (nonatomic, strong) NSMutableArray *friendsSuggested; // of PFUser*
@property (nonatomic, strong) NSMutableArray *suggestionButtons;

@property (nonatomic) BOOL loadedRequests;
@property (nonatomic) BOOL loadedSuggestions;
@property (nonatomic) BOOL loadedFriends;

@end
