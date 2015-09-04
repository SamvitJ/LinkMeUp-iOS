//
//  Logs.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/25/15.
//
//

#import "Logs.h"

#import <Parse/PFObject+Subclass.h>

@implementation Logs

@dynamic user;
@dynamic name;
@dynamic sessionLoginStatus;
@dynamic versionInstalled;
@dynamic installation;
@dynamic messages;

+ (NSString *)parseClassName
{
    return @"Logs";
}

@end
