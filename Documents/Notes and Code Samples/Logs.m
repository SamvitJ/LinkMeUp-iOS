//
//  Logs.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/18/15.
//
//

#import "Logs.h"

#import <Parse/PFObject+Subclass.h>

@implementation Logs

@dynamic user;
@dynamic name;
@dynamic messages;

+ (NSString *)parseClassName
{
    return @"Logs";
}

@end
