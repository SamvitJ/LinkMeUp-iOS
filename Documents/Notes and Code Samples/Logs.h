//
//  Logs.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/18/15.
//
//

#import <Parse/Parse.h>

@interface Logs : PFObject <PFSubclassing>

@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSMutableArray *messages;

@end
