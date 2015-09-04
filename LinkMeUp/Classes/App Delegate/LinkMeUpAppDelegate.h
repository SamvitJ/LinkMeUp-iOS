//
//  LinkMeUpAppDelegate.h
//  LinkMeUp
//
//  Created by Samvit Jain
//

#import <UIKit/UIKit.h>

#import "Data.h"

#import "LaunchViewController.h"

#import "Logs.h"

@interface LinkMeUpAppDelegate : NSObject <UIApplicationDelegate, UIActionSheetDelegate, UITabBarControllerDelegate>

// application data model
@property (nonatomic, strong) Data *myData;

// logs
@property (nonatomic, strong) Logs *sessionLogs;

// UI elements
@property (nonatomic, strong) IBOutlet UIWindow *window;

// associated VCs
@property (nonatomic, strong) launchViewController *launchVC;
@property (nonatomic, strong) UITabBarController *tbc;

// data refresh timer (if push notifications off)
@property (nonatomic, strong) NSTimer *updateTimer;

// push notification info
@property (nonatomic, strong) NSDictionary *notificationPayload;

// interent connectivity
@property (nonatomic) BOOL internetActive;

// background task object
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

// application set up
- (void)initializeData;
- (void)duplicateMasterLinks;
- (void)loadData;
- (void)setUpApplicationViewControllers;

// push notifications
- (UIUserNotificationType)getEnabledNotificationTypes;
- (void)updateApplicationBadge;

// internet connectivity
- (void)checkNetworkStatus:(NSNotification *)notice;

// session logs
- (void)saveSessionLogsToParse;

@end

