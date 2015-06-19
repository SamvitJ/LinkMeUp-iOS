//
//  LinkMeUpAppDelegate.m
//  LinkMeUp
//
//  Created by Samvit Jain
//

#import "LinkMeUpAppDelegate.h"

#import "Reachability.h"

#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>

#import "Constants.h"
#import "Link.h"
#import "FriendRequest.h"

#import "DefaultSettingsViewController.h"

#import "inboxViewController.h"
#import "searchViewController.h"
#import "friendsViewController.h"

@interface LinkMeUpAppDelegate ()
@end

@implementation LinkMeUpAppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.

    // Parse Initialization
    [Link registerSubclass];
    [FriendRequest registerSubclass];
    [Parse setApplicationId:PARSE_APP_ID clientKey:PARSE_CLIENT_KEY];
    [PFFacebookUtils initializeFacebook];

    /* // Twitter
    [PFTwitterUtils initializeWithConsumerKey:@"your_twitter_consumer_key" consumerSecret:@"your_twitter_consumer_secret"];
    // Parse analytics tracking
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions]; */
    
    // Set default ACLs
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    // Initialize view controllers
    self.ds = [[DefaultSettingsViewController alloc] init];
    [self.window setRootViewController:self.ds];
    [self.window makeKeyAndVisible];
    
    // set didShowPushVCThisSession to NO
    [[NSUserDefaults standardUserDefaults] setObject:@NO forKey: kDidShowPushVCThisSession];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Determine if app was launched from push notification
    NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    self.notificationPayload = notificationPayload;
    
    // Set up reachability tests and subscribe to notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];     
    [networkReachability startNotifier];
    
    // Allow audio playback on "Silent" setting
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:nil error:nil];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    NSLog(@"Did become active");
    
    // FB
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
    
    // special case code
    // if push notif alert view was presented, notify pushNotifVC that user responded
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kDidPresentPushNotifAlertView] boolValue])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserRespondedToPushNotifAlertView object:nil];
    }
    
    // if push notifications are off, configure timer to reload data regularly
    UIUserNotificationType remoteNotification = [self getEnabledNotificationTypes];
    
    if (remoteNotification == UIRemoteNotificationTypeNone)
    {
        NSLog(@"Notifications - None");
        
        // Load data from server periodically
        if (!self.updateTimer)
        {
            [self reloadData];
            self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(reloadData) userInfo:nil repeats:YES];
        }
    }
    
    else
    {
        if (remoteNotification & UIRemoteNotificationTypeAlert)
        {
            NSLog(@"Notifications - Alert");
            
            // if push notifications now on (and were previously off)
            if (self.updateTimer)
            {
                [self.updateTimer invalidate];
                self.updateTimer = nil;
            }
            
            // in case of new links/requests/messages
            [self reloadData];
        }
        else
        {
            // Load data from server periodically
            if (!self.updateTimer)
            {
                [self reloadData];
                self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(reloadData) userInfo:nil repeats:YES];
            }
            
            if (remoteNotification & UIRemoteNotificationTypeBadge)
            {
                NSLog(@"Notifications - Badge");
            }
            
            if (remoteNotification & UIRemoteNotificationTypeSound)
            {
                NSLog(@"Notifications - Sound");
            }
            
            if (remoteNotification & UIRemoteNotificationTypeNewsstandContentAvailability)
            {
                NSLog (@"Notifications - ContentAvailability");
            }
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    NSLog(@"Will resign active");
    
    // special case code
    // if attempted to register for push notif, and now leaving the app, push notif alert view was presented
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kDidAttemptToRegisterForPushNotif] boolValue])
    {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey: kDidPresentPushNotifAlertView];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    NSLog(@"Application did enter background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
    NSLog(@"Application will terminate");
    
    // unsubscribe to notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

#pragma mark - UITabBarController delegate

/*- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    UINavigationController *leftNav = tabBarController.viewControllers[kTabBarIconInbox];
    
    if (viewController == leftNav) // if user selected left tab
    {
        inboxViewController *ivc = leftNav.viewControllers[0]; // root VC
        
        if (self.myData.receivedLinkUpdates > 0 && self.myData.sentLinkUpdates == 0)
            ivc.selectedSegment = kInboxReceived;
        
        else if (self.myData.sentLinkUpdates > 0 && self.myData.receivedLinkUpdates == 0)
            ivc.selectedSegment = kInboxSent;
        
        [ivc.tableView reloadData];
    }
    
    return YES;
}*/

#pragma mark - Application set up

- (void)initializeData
{
    self.myData = [[Data alloc] init];
}

- (void)duplicateMasterLinks
{
    [self.myData duplicateMasterLinks];
    
    // load received links on notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMasterLinks) name:@"postedMasterLinks" object:nil];
}

- (void)loadMasterLinks
{
    // unsubscribe
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"postedMasterLinks" object:nil];
    
    [self.myData loadReceivedLinks: kPriorityHigh];
}

- (void)loadData
{
    [self.myData loadAllData];
}

- (void)reloadData
{
    if (self.myData)
    {
        // *LOW PRIORITY UPDATES*
        if (self.myData.loadedConnections)
        {
            [self.myData loadConnections];
        }
        
        if (self.myData.loadedReceivedLinks && self.myData.loadedSentLinks)
        {
            [self.myData loadReceivedLinks: kPriorityLow];
            [self.myData loadSentLinks: kPriorityLow];
        }
    }
}

- (void)setUpApplicationViewControllers
{
    self.tbc = [[UITabBarController alloc] init];
    self.tbc.delegate = self;
    //self.tbc.extendedLayoutIncludesOpaqueBars = NO;
    self.tbc.edgesForExtendedLayout = UIRectEdgeNone;
    
    UINavigationController *leftNav = [[UINavigationController alloc] init];
    leftNav.navigationBarHidden = YES;
    inboxViewController *ivc = [[inboxViewController alloc] init]; ivc.selectedSegment = kInboxReceived;
    [leftNav pushViewController:ivc animated:NO];
    
    UINavigationController *middleNav = [[UINavigationController alloc] init];
    middleNav.navigationBarHidden = YES;
    searchViewController *svc = [[searchViewController alloc] init];
    [middleNav pushViewController:svc animated:NO];
    
    UINavigationController *rightNav = [[UINavigationController alloc] init];
    rightNav.navigationBarHidden = YES;
    friendsViewController *fvc = [[friendsViewController alloc] init];
    [rightNav pushViewController:fvc animated:NO];
    
    self.tbc.viewControllers = [NSArray arrayWithObjects:leftNav, middleNav, rightNav, nil];
    self.tbc.selectedViewController = middleNav;
    self.tbc.tabBar.barTintColor = [UIColor blackColor];
    
    UITabBarItem *inbox = [[UITabBarItem alloc] init];
    UIImage *inboxIcon = [UIImage imageNamed:@"Closed-Mail"];
    inbox.image = [UIImage imageWithCGImage:[inboxIcon CGImage]
                                      scale:(inboxIcon.scale * 1.5) // scale down
                                orientation:inboxIcon.imageOrientation];
    inbox.title = @"Inbox";
    leftNav.tabBarItem = inbox;
    
    UITabBarItem *messenger = [[UITabBarItem alloc] init];
    UIImage *messengerIcon = [UIImage imageNamed:@"Radio-Tower"];
    messenger.image = [UIImage imageWithCGImage:[messengerIcon CGImage]
                                          scale:(messengerIcon.scale * 1.9) // scale down
                                    orientation:messengerIcon.imageOrientation];
    messenger.title = @"Send Link";
    middleNav.tabBarItem = messenger;
    
    UITabBarItem *friends = [[UITabBarItem alloc] init];
    UIImage *friendsIcon = [UIImage imageNamed:@"glyphicons_043_group"];
    friends.image = [UIImage imageWithCGImage:[friendsIcon CGImage]
                                        scale:(friendsIcon.scale * 1.5) // scale down
                                  orientation:friendsIcon.imageOrientation];
    friends.title = @"Friends";
    rightNav.tabBarItem = friends;
}

#pragma mark - Push notifications

- (UIUserNotificationType)getEnabledNotificationTypes
{
    UIRemoteNotificationType enabledRemoteNotificationTypes;
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)])
    {
        // iOS 8+
        UIUserNotificationSettings *userNotificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        enabledRemoteNotificationTypes = userNotificationSettings.types;
    }
    else
    {
        // iOS 7 and below
        enabledRemoteNotificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    }
    
    // other tests
    // if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
    
    return enabledRemoteNotificationTypes;
}

- (void)updateApplicationBadge
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];

    currentInstallation.badge = self.myData.receivedLinkUpdates + self.myData.sentLinkUpdates + self.myData.sentRequestUpdates + self.myData.receivedRequestUpdates;
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Did fail to register for remote notifications %@", error);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidFailToRegisterForPush object:nil];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
    NSLog(@"Did register for remote notifications");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidRegisterForPush object:nil];
    
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error)
        {
            NSLog(@"Error saving current installation in Parse %@ %@", error, [error userInfo]);
        }
        else
        {
            NSLog(@"Saved current installation in Parse");
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"User info %@", userInfo);
    
    // new link
    if ([[userInfo objectForKey:@"type"] isEqualToString:@"link"])
    {
        UINavigationController *leftNav = self.tbc.viewControllers[kTabBarIconInbox];
        inboxViewController *ivc = leftNav.viewControllers[0];
        
        // set inbox status
        ivc.receivedPush = YES;
        
        // load data from server
        // *HIGH PRIORITY UPDATE*
        [self.myData loadReceivedLinks: kPriorityHigh];
        
        // app in foreground
        if (application.applicationState == UIApplicationStateActive)
        {
            // update app badge number
            application.applicationIconBadgeNumber = [[[userInfo objectForKey:@"aps"] objectForKey:@"badge"] intValue];
        }
        
        // app in background
        else
        {
            // switch seg to received links
            ivc.selectedSegment = kInboxReceived;
            
            // show inbox
            [leftNav popToRootViewControllerAnimated:NO];
            self.tbc.selectedViewController = leftNav;
        }
    }
    
    // new message or like/love response
    else if ([[userInfo objectForKey:@"type"] isEqualToString:@"message"] || [[userInfo objectForKey:@"type"] isEqualToString:@"emotion"])
    {
        UINavigationController *leftNav = self.tbc.viewControllers[kTabBarIconInbox];
        inboxViewController *ivc = leftNav.viewControllers[0];
        
        // set inbox status
        ivc.receivedPush = YES;
        
        // load data from server
        // *HIGH PRIORITY UPDATE*
        (([[userInfo objectForKey:@"isSender"] boolValue] == YES) ? [self.myData loadSentLinks: kPriorityHigh] : [self.myData loadReceivedLinks: kPriorityHigh]);
        
        // app in foreground
        if (application.applicationState == UIApplicationStateActive)
        {
            // update app badge number
            application.applicationIconBadgeNumber = [[[userInfo objectForKey:@"aps"] objectForKey:@"badge"] intValue];
        }
        
        // app in background
        else
        {
            // switch segment
            ivc.selectedSegment = (([[userInfo objectForKey:@"isSender"] boolValue] == YES) ? kInboxSent : kInboxReceived);
            
            // show inbox
            [leftNav popToRootViewControllerAnimated:NO];
            self.tbc.selectedViewController = leftNav;
        }
    }
    
    // new friend request
    else if ([[userInfo objectForKey:@"type"] isEqualToString:@"request"])
    {
        UINavigationController *rightNav = self.tbc.viewControllers[kTabBarIconFriends];
        friendsViewController *fvc = rightNav.viewControllers[0];
        
        // set friends tab status
        fvc.receivedPush = YES;
        
        // Load data from server
        // *HIGH PRIORITY UPDATES*
        [self.myData loadConnections];
        
        // app in foreground
        if (application.applicationState == UIApplicationStateActive)
        {
            // update icon badge number
            application.applicationIconBadgeNumber = [[[userInfo objectForKey:@"aps"] objectForKey:@"badge"] intValue];
        }
        
        // app in background
        else
        {
            // show friends tab
            [rightNav popToRootViewControllerAnimated:NO];
            self.tbc.selectedViewController = rightNav;
        }
    }
}

#pragma mark - Network status

- (void)checkNetworkStatus:(NSNotification *)notice
{
    NSLog(@"Checking network status");
    
    // called after network status changes
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [networkReachability currentReachabilityStatus];
    switch (internetStatus)
    {
        case NotReachable:
        {
            NSLog(@"The internet is down.");
            self.internetActive = NO;
            
            [[[UIAlertView alloc] initWithTitle:@"No internet"
                                        message:@"Please check your connection"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            
            break;
        }
        case ReachableViaWiFi:
        {
            NSLog(@"The internet is working via wifi.");
            self.internetActive = YES;
            
            break;
        }
        case ReachableViaWWAN:
        {
            NSLog(@"The internet is working via WWAN.");
            self.internetActive = YES;
            
            break;
        }
        default:
            break;
    }
}

#pragma mark - Log Out

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) // log out pressed
        [self logOut];
}

- (void)logOut
{
    // set push notification badge to 0 (Parse)
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.badge = 0;
    
    // unregister for push notifications
    [currentInstallation removeObject:[NSString stringWithFormat:@"user_%@", self.myData.me.objectId] forKey:@"channels"];
    [currentInstallation saveInBackground];
    
    // set didShowPushVCThisSession to NO
    [[NSUserDefaults standardUserDefaults] setObject:@NO forKey: kDidShowPushVCThisSession];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // pop all tabs to root view controller
    for (UINavigationController *vc in self.tbc.viewControllers)
        [vc popToRootViewControllerAnimated:NO];
    
    // display login screen
    [self.window setRootViewController:self.ds];
    
    // logout Parse/FB user
    [PFUser logOut];
    
    NSLog(@"Logged out");
}

#pragma mark - Facebook oauth callback

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url sourceApplication:sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
    NSLog(@"App delegate did receive memory warning");
}


@end
