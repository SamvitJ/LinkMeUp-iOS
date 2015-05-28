//
//  FriendRequest.h
//  LinkMeUp
//
//  Created by Samvit Jain on 6/27/14.
//
//

#import <Parse/Parse.h>

@interface FriendRequest : PFObject <PFSubclassing>

@property (nonatomic, strong) PFUser *sender;
@property (nonatomic, strong) PFUser *receiver;

@property (nonatomic) BOOL seen;
@property (nonatomic) BOOL accepted;

@end
