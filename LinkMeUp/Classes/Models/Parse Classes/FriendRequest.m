//
//  FriendRequest.m
//  LinkMeUp
//
//  Created by Samvit Jain on 6/27/14.
//
//

#import "FriendRequest.h"

#import <Parse/PFObject+Subclass.h>

@implementation FriendRequest

@dynamic sender, receiver;
@dynamic seen, accepted;

+ (NSString *)parseClassName
{
    return @"FriendRequest";
}

@end
