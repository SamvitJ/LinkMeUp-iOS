//
//  Logs.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/25/15.
//
//

#import <Parse/Parse.h>

#import "Constants.h"

@interface Logs : PFObject <PFSubclassing>

@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong) NSString *name;

@property (nonatomic) SessionLoginStatus sessionLoginStatus;

@property (nonatomic, strong) NSString *versionInstalled;
@property (nonatomic, strong) PFInstallation *installation;

@property (nonatomic, strong) NSMutableArray *messages;

@end
