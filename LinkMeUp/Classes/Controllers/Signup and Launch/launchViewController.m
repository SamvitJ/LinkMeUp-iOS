//
//  LaunchViewController.m
//  (Before 9/4/15) DefaultSettingsViewController.m
//
//  LinkMeUp
//
//  Created by Samvit Jain on 6/19/14.
//
//

#import "launchViewController.h"

#import "Constants.h"
#import "Data.h"

#import <ParseFacebookUtils/PFFacebookUtils.h>

#import "LinkMeUpAppDelegate.h"

#import "myLogInViewController.h"
#import "mySignUpViewController.h"
#import "pushNotifViewController.h"

#import "inboxViewController.h"
#import "friendsViewController.h"

@interface launchViewController ()

@end

@implementation launchViewController



#pragma mark - Application launch methods

- (void)launchLogIn
{
    [self presentViewController:self.myLogIn animated:YES completion:nil];
}

- (void)launchApplication:(ApplicationLaunch)launchType
{
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // update installation with latest user info
    [self setUserInfoOnInstallation];
    
    // post session logs to Parse (pre-launch)
    [appDelegate saveSessionLogsToParse];
    
    if (launchType == kApplicationLaunchNew)
    {
        // set up application for launch
        [appDelegate initializeData];
        [appDelegate setUpApplicationViewControllers];
        
        [appDelegate duplicateMasterLinks];
        [appDelegate loadData];
        
        [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(launchNew) userInfo:nil repeats:NO];
    }
    
    else // if (launchType == kApplicationLaunchReturning)
    {
        // set up application for launch
        [appDelegate initializeData];
        [appDelegate setUpApplicationViewControllers];
        
        [appDelegate loadData];
        
        // present push notification screen, if applicable
        UIUserNotificationType remoteNotification = [appDelegate getEnabledNotificationTypes];
        PFUser *me = [PFUser currentUser];
       
        BOOL didShowPushVC = [[[NSUserDefaults standardUserDefaults] objectForKey:kDidShowPushVCThisSession] boolValue];
        
        if (remoteNotification == UIRemoteNotificationTypeNone
            && [me[kNumberPushRequests] integerValue] < PUSH_REQUESTS_LIMIT
            && !didShowPushVC)
        {
            pushNotifViewController *pnvc = [[pushNotifViewController alloc] init];
            [self presentViewController:pnvc animated:YES completion: nil];
        }
        else
        {
            [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(launchReturning) userInfo:nil repeats:NO];
        }
    }
}

- (void)launchNew
{
    // clear standard user default
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@_%@", [PFUser currentUser].objectId, kDidNotLaunchNewAccount]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[UIApplication sharedApplication].delegate;
    
    UITabBarController *tbc = appDelegate.tbc;
    tbc.selectedViewController = tbc.viewControllers[kTabBarIconInbox];
    
    [self clearStatusLabel];
    [appDelegate.window setRootViewController:appDelegate.tbc];
}

- (void)launchReturning
{
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[UIApplication sharedApplication].delegate;
    UITabBarController *tbc = appDelegate.tbc;
    
    if (appDelegate.notificationPayload) // app opened with push notif
    {
        UINavigationController *nav;
        
        // new link
        if ([appDelegate.notificationPayload[@"type"] isEqualToString:@"link"])
        {
            nav = tbc.viewControllers[kTabBarIconInbox];
            
            inboxViewController *ivc = nav.viewControllers[0];
            ivc.receivedPush = YES;
            ivc.selectedSegment = kInboxReceived;
        }
        
        // new message or like/love
        else if ([appDelegate.notificationPayload[@"type"] isEqualToString:@"message"] ||
                 [appDelegate.notificationPayload[@"type"] isEqualToString:@"emotion"])
        {
            nav = tbc.viewControllers[kTabBarIconInbox];
            
            inboxViewController *ivc = nav.viewControllers[0];
            ivc.receivedPush = YES;
            ivc.selectedSegment = ([appDelegate.notificationPayload[@"isSender"] boolValue] ? kInboxSent : kInboxReceived);
        }
        
        // friend request (new received or accepted)
        else if ([appDelegate.notificationPayload[@"type"] isEqualToString:@"request"])
        {
            nav = tbc.viewControllers[kTabBarIconFriends];
            
            friendsViewController *fvc = nav.viewControllers[0];
            fvc.receivedPush = YES;
        }
        
        tbc.selectedViewController = nav;
        [appDelegate.window setRootViewController:appDelegate.tbc];
    }
    
    else // app opened without push notif
    {
        tbc.selectedViewController = tbc.viewControllers[kTabBarIconMessenger]; // send song tab
        [appDelegate.window setRootViewController:appDelegate.tbc];
    }
    
    // show network alert
    if (!appDelegate.internetActive)
        [appDelegate checkNetworkStatus:nil];
}

#pragma mark - View controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIImageView *launchScreen = [[UIImageView alloc] initWithFrame:(IS_IPHONE_5 ? CGRectMake(0, 0, 320, 568) : CGRectMake(0, 0, 320, 480))];
    launchScreen.image = (IS_IPHONE_5 ? [UIImage imageNamed:@"LaunchImage-568h@2x"] : [UIImage imageNamed:@"LaunchImage@2x"]);
    
    [self.view addSubview: launchScreen];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[UIApplication sharedApplication].delegate;
    PFUser *user = [PFUser currentUser];
    
    // did user terminate signup process or have existing account with same (facebook) email?
    NSNumber *unverified = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%@", user.objectId, kDidNotVerifyNumber]];
    NSNumber *didNotLaunch = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%@", user.objectId, kDidNotLaunchNewAccount]];
    NSNumber *existingAccount = [[NSUserDefaults standardUserDefaults] objectForKey:kDidCreateAccountWithSameEmail];
    
    // No user logged in OR terminated signup process OR existing account
    if (!user || [unverified boolValue] == YES || [existingAccount boolValue] == YES)
    {
        if ([unverified boolValue] == YES)
        {
            NSLog(@"User terminated signup process without verifying number");
            
            // clear standard user default
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@_%@", user.objectId, kDidNotVerifyNumber]];
            [[NSUserDefaults standardUserDefaults] synchronize];

            // if account linked with Facebook, clear FB token info
            if ([PFFacebookUtils isLinkedWithUser: user])
                [[FBSession activeSession] closeAndClearTokenInformation];
            
            // delete user
            [user deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error)
                {
                    NSLog(@"Error deleting user in background %@", error);
                }
            }];
            
            // set logout status and post session logs to Parse
            appDelegate.sessionLogs.sessionLoginStatus = kSessionLoginStatusLoggedOut;
            [appDelegate saveSessionLogsToParse];
        }
        else if ([existingAccount boolValue] == YES)
        {
            NSLog(@"Existing account with same email");
            
            [[[UIAlertView alloc] initWithTitle:@"Existing account"
                                        message:@"It seems like you already have an account with this email. Please log in to your existing account."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            
            // clear standard user default
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDidCreateAccountWithSameEmail];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // clear FB token info
            [[FBSession activeSession] closeAndClearTokenInformation];
            
            // delete user
            [user deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error)
                {
                    NSLog(@"Error deleting user in background %@", error);
                }
            }];
            
            // set logout status and post session logs to Parse
            appDelegate.sessionLogs.sessionLoginStatus = kSessionLoginStatusLoggedOut;
            [appDelegate saveSessionLogsToParse];
        }
        
        // NSLog(@"NSUserDefaults %@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
        
        // Create the log in view controller
        self.myLogIn = [[myLogInViewController alloc] init];
        [self.myLogIn setDelegate:self]; // Set ourselves as the delegate
        
        // Set FB permissions
        NSArray *permissionsArray = @[@"public_profile", @"user_friends", @"email"];
        [self.myLogIn setFacebookPermissions:permissionsArray];
        self.myLogIn.fields = (PFLogInFields)(PFLogInFieldsDefault | PFLogInFieldsFacebook);
        
        // Create the sign up view controller
        mySignUpViewController *signUpViewController = [[mySignUpViewController alloc] init];
        //signUpViewController.fields = (PFSignUpFields)(PFSignUpFieldsUsernameAndPassword | PFSignUpFieldsSignUpButton | PFSignUpFieldsDismissButton);
        [signUpViewController setDelegate:self]; // Set ourselves as the delegate
        
        // Assign our sign up controller to be displayed from the login controller
        [self.myLogIn setSignUpController:signUpViewController];
        
        // Present the log in view controller
        [self launchLogIn];
    }

    else if (user.isNew || [didNotLaunch boolValue] == YES) // new user
    {
        // create status label
        [self createStatusLabel];
        
        // used to determine whether to present findContactsVC
        [[NSUserDefaults standardUserDefaults] setObject:@NO forKey: kDidEnterFriendsVC];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSLog(@"Now welcoming");
        
        // new account is a facebook account (created through "login with facebook" option)
        if ([PFFacebookUtils isLinkedWithUser: user])
        {
            NSLog(@"New account via FB log in");
            [self setWelcomeLabelForUser: user[@"first_name"]];
            [self launchApplication: kApplicationLaunchNew];
        }
        else // new account is a LMU account
        {
            NSLog(@"New LMU account");
            [self setWelcomeLabelForUser: user.username];
            [self launchApplication: kApplicationLaunchNew];
        }
    }
    
    else // user logged in
    {
        NSLog(@"User logged in");
        
        // fix for existing users with Facebook signup issue
        if ([PFFacebookUtils isLinkedWithUser:user] && !user.email && !user[@"name"])
        {
            NSLog(@"Resolving Facebook signup issue for existing user");
            [self getUserDataFromFacebook];
        }
        
        [self launchApplication: kApplicationLaunchReturning];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Facebook oauth callback

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

#pragma mark - PFLogInViewController delegate methods

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password
{
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0)
        return YES; // Begin login process
    
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user
{
    NSLog(@"Callback -logInVC: didLogInUser: entered");
    
    // set user/name property on session logs and installation
    [self setUserInfoInSessionLogs];
    [self setUserInfoOnInstallation];
    
    // post session logs to Parse
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate saveSessionLogsToParse];
    
    // new account via Facebook
    PFUser *me = [PFUser currentUser];
    if (me.isNew && [PFFacebookUtils isLinkedWithUser:(PFUser *)user])
    {
        // check granted Facebook permissions
        bool hasProfile = [self hasProfilePermission];
        bool hasEmail = [self hasEmailPermission];
        
        // NSLog(@"%u %u", hasProfile, hasEmail);
        
        // if declined both permissions, show alert and return
        if (!hasProfile && !hasEmail)
        {
            [self handleDeniedPermissions];
            return;
        }

        // set NSUserDefault statuses
        [self setVerificationAndLaunchStatuses];
        
        // set mobile verification status in Parse
        me[@"mobileVerified"] = [NSNumber numberWithBool:NO];
        
        // use FB data to set PFUser info, if possible
        [self getUserDataFromFacebook];
        
        // continue signup process
        verificationViewController *vvc = [[verificationViewController alloc] init];
        [self.myLogIn presentViewController:vvc animated:YES completion:nil];
    }
    
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error
{
    NSLog(@"Failed to log in... %@", error);
    
    // Internal server error || ConnectionFailed || Failed to initialize mongo connection
    if (error.code == 1 || error.code == 100 || error.code == 159)
    {
        [[[UIAlertView alloc] initWithTitle:@"Server Issues"
                                    message:@"We're sorry, but we're experiencing server issues :( \nPlease try again in a bit."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    else if (error.code == 101)
    {
        [[[UIAlertView alloc] initWithTitle:@"Incorrect username or password"
                                    message:@""
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController
{
    NSLog(@"Login cancelled");
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Signup with Facebook

- (void)getUserDataFromFacebook
{
    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *fbUser, NSError *error) {
        if (!error)
        {
            // use FB data to set PFUser info
            [self setInfoForFBGraphUser:fbUser];
        }
        else
        {
            NSLog(@"Error requesting for FBGraphUser %@ %@", error, [error userInfo]);
            
            if (fbUser)
            {
                NSLog(@"Non fatal error - FBGraphUser available %@", fbUser);
                [self setInfoForFBGraphUser:fbUser];
            }
            else
            {
                NSLog(@"Fatal error - FBGraphUser unavailable");
            }
        }
    }];
}

- (void)setInfoForFBGraphUser:(NSDictionary<FBGraphUser> *)fbUser
{
    PFUser *me = [PFUser currentUser];
    
    // username
    NSString *oldUsername = me.username;
    NSString *newUsername = fbUser[@"email"];
    if (!newUsername)
    {
        if (fbUser.first_name || fbUser.last_name)
            newUsername = [NSString stringWithFormat:@"%@%@", fbUser.first_name, fbUser.last_name];
        
        else NSLog(@"Both email and name not provided by user/available");
    }
    
    // name
    NSString *fullName;
    if (fbUser.first_name && fbUser.last_name)
    {
        fullName = [NSString stringWithFormat:@"%@ %@", fbUser.first_name, fbUser.last_name];
    }
    else if (fbUser.first_name)
    {
        fullName = fbUser.first_name;
    }
    
    // set critical info
    me.username = newUsername;
    me.email = fbUser[@"email"];
    
    // supplemental info
    me[@"facebook_id"] = fbUser[@"id"];
    me[@"name"] = fullName;
    me[@"first_name"] = fbUser.first_name;
    
    [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (error)
        {
            NSLog(@"Error saving user info to Parse (new account creation via Facebook) %@ %@", error, [error userInfo]);
            
            if (error.code == 202 || error.code == 203)
            {
                NSLog(@"Username or email is taken");
                
                [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kDidCreateAccountWithSameEmail];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                me.username = oldUsername;
                me.email = nil;
                me[@"facebook_email"] = fbUser[@"email"];
                
                [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error)
                    {
                        NSLog(@"Error saving user info to Parse (after discovering existing account with same email) %@ %@", error, [error userInfo]);
                    }
                }];
            }
            else
            {
                if (error.code == 125)
                {
                    NSLog(@"Facebook email is invalid");
                }
                
                me.email = nil;
                me[@"facebook_email"] = fbUser[@"email"];
                
                [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error)
                    {
                        NSLog(@"Error saving user info to Parse (after discovering some other error) %@ %@", error, [error userInfo]);
                    }
                }];
            }
        }
        
    }];
}

- (bool)hasProfilePermission
{
    NSArray *permissions = [[[PFFacebookUtils session] accessTokenData] permissions];
    
    for (NSString *entry in permissions)
    {
        if ([entry isEqualToString:@"public_profile"])
            return true;
    }
    
    NSLog(@"Profile permission denied");
    return false;
}

- (bool)hasEmailPermission
{
    NSArray *permissions = [[[PFFacebookUtils session] accessTokenData] permissions];
    
    for (NSString *entry in permissions)
    {
        if ([entry isEqualToString:@"email"])
            return true;
    }
    
    NSLog(@"Email permission denied");
    return false;
}

- (void)handleDeniedPermissions
{
    NSLog(@"Denied permissions - email address or name must be provided");
    
    // delete user
    [[PFUser currentUser] deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error)
        {
            NSLog(@"Error deleting user in background %@", error);
        }
    }];
    
    // set logout status and post session logs to Parse
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.sessionLogs.sessionLoginStatus = kSessionLoginStatusLoggedOut;
    [appDelegate saveSessionLogsToParse];
    
    // initialize alert views
    NSString *alertTitle = @"Denied Permissions";
    NSString *alertMessage = [NSString stringWithFormat: @"\nYour name and email address are required to create an account.\n\n Please press the signup button to make an account with LinkMeUp."];
    
    if (IS_IOS8)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                 message:alertMessage
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                style: UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  
                                                                  // do nothing
                                                                  return;
                                                              }];
        
        [alertController addAction: defaultAction];
        
        [self.myLogIn presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                            message:alertMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // do nothing
    return;
}

#pragma mark - PFSignUpViewController delegate methods

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info
{
    BOOL informationComplete = YES;
    BOOL passwordSecure = YES;
    
    // loop through all of the submitted data
    for (id key in info)
    {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) // check completion
        {
            informationComplete = NO;
            break;
        }
        if ([key isEqualToString:@"password"] && field.length < 6) // check password length
        {
            passwordSecure = NO;
            break;
        }
    }
    
    // Display an alert if a field wasn't completed
    if (!informationComplete)
    {
        NSLog(@"Missing information");
        
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you fill out all of the information!"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    
    if (!passwordSecure)
    {
        NSLog(@"Password too short");
        
        [[[UIAlertView alloc] initWithTitle:@"Password Too Short"
                                    message:@"Your password must be at least 6 characters"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    
    return (informationComplete && passwordSecure);
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user
{
    NSLog(@"Callback -signUpVC: didSignUpUser: entered");
    
    mySignUpViewController *mySignUp = (mySignUpViewController *)signUpController;
    mySignUp.verificationVC = [[verificationViewController alloc] init];
    
    // set user/name property on session logs and installation
    [self setUserInfoInSessionLogs];
    [self setUserInfoOnInstallation];
    
    // post session logs to Parse
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate saveSessionLogsToParse];
    
    // set NSUserDefault statuses
    [self setVerificationAndLaunchStatuses];
    
    // set mobile verification status in Parse
    PFUser *me = [PFUser currentUser];
    me[@"mobileVerified"] = [NSNumber numberWithBool:NO];
    [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error)
        {
            NSLog(@"Error saving verification status (false) %@ %@", error, [error userInfo]);
        }
    }];
    
    [mySignUp presentViewController:mySignUp.verificationVC animated:YES completion:nil];
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error
{
    NSLog(@"Failed to sign up... %@", error);
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController
{
    NSLog(@"User cancelled signup");
}

#pragma mark - Installations

- (void)setUserInfoOnInstallation
{
    // add user to 'currentUser', 'allUsers', and 'channels' fields of current installation (if not already added)
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    
    currentInstallation[@"currentUser"] = [PFUser currentUser];
    
    PFRelation *allUsers = [currentInstallation relationForKey:@"allUsers"];
    [allUsers addObject: [PFUser currentUser]];
    
    [currentInstallation addUniqueObject:[NSString stringWithFormat:@"user_%@", [PFUser currentUser].objectId] forKey:@"channels"];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error)
        {
            NSLog(@"Error saving installation to Parse after adding user to channels %@ %@", error, [error userInfo]);
        }
    }];
}

#pragma mark - Session logs

- (void)setUserInfoInSessionLogs
{
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
    PFUser *me = [PFUser currentUser];
    
    // set login status
    appDelegate.sessionLogs.sessionLoginStatus = kSessionLoginStatusLoggedIn;
    
    // set user/name properties
    appDelegate.sessionLogs.user = me;
    appDelegate.sessionLogs.name = [Constants nameElseUsername: me];
}

#pragma mark - Verification and launch statuses

- (void)setVerificationAndLaunchStatuses
{
    // user began sign up process
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:[NSString stringWithFormat:@"%@_%@", [PFUser currentUser].objectId, kDidNotLaunchNewAccount]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // user account unverified
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:[NSString stringWithFormat:@"%@_%@", [PFUser currentUser].objectId, kDidNotVerifyNumber]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // NSLog(@"NSUserDefaults: %@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
}

#pragma mark - UI helper methods

- (void)createStatusLabel
{
    // to avoid label pileup
    // Q: in what cases could this happen?
    [self.statusLabel removeFromSuperview];
    
    CGFloat labelWidth = 300.0;
    CGFloat labelHeight = 40.0;
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - labelWidth)/2, (self.view.frame.size.height - labelHeight)/2, labelWidth, labelHeight)];

    self.statusLabel.text = @"";
    
    [self.view addSubview:self.statusLabel];
}

- (void)setWelcomeLabelForUser:(NSString *)name
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    UIFont *labelFont = HELV_LIGHT_20;
    UIColor *labelColor = [UIColor whiteColor];
    
    NSString *welcomeText = [NSString stringWithFormat:@"Welcome %@!", name];
    
    NSMutableAttributedString *welcomeLabelText = [[NSMutableAttributedString alloc] initWithString:welcomeText
                                                                                         attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                                        NSFontAttributeName: labelFont,
                                                                                                        NSForegroundColorAttributeName: labelColor}];
    
    // add accent to user name
    [welcomeLabelText addAttribute:NSFontAttributeName
                             value:HELV_20
                             range:NSMakeRange([NSString stringWithFormat:@"Welcome"].length, welcomeText.length - [NSString stringWithFormat:@"Welcome"].length)];
    
    [self.statusLabel setAttributedText:welcomeLabelText];
}

- (void)setLoadingLabel
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    UIFont *labelFont = HELV_LIGHT_20;
    UIColor *labelColor = [UIColor whiteColor];
    
    NSString *loadingText = [NSString stringWithFormat:@"Loading account..."];
    
    NSMutableAttributedString *loadingLabelText = [[NSMutableAttributedString alloc] initWithString: loadingText
                                                                                  attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                                 NSFontAttributeName: labelFont,
                                                                                                 NSForegroundColorAttributeName: labelColor}];
    
    [self.statusLabel setAttributedText:loadingLabelText];
}

- (void)clearStatusLabel
{
    self.statusLabel.text = @"";
    [self.statusLabel removeFromSuperview];
}

@end
