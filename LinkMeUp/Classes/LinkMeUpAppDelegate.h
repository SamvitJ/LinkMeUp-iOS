//
//  LinkMeUpAppDelegate.h
//  LinkMeUp
//
//  Created by Samvit Jain
//

#import <UIKit/UIKit.h>

#import "Data.h"

#import "DefaultSettingsViewController.h"

@interface LinkMeUpAppDelegate : NSObject <UIApplicationDelegate, UIActionSheetDelegate, UITabBarControllerDelegate>

// application data model
@property (nonatomic, strong) Data *myData;

// UI elements
@property (nonatomic, strong) IBOutlet UIWindow *window;

// associated VCs
@property (nonatomic, strong) DefaultSettingsViewController *ds;
@property (nonatomic, strong) UITabBarController *tbc;

// data refresh timer (if push notifications off)
@property (nonatomic, strong) NSTimer *updateTimer;

// push notification info
@property (nonatomic, strong) NSDictionary *notificationPayload;

// interent connectivity
@property (nonatomic) BOOL internetActive;

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

@end

