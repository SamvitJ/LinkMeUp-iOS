//
//  DefaultSettingsViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 6/19/14.
//
//

#import "DefaultSettingsViewController.h"

#import "Constants.h"
#import "Data.h"

#import <ParseFacebookUtils/PFFacebookUtils.h>

#import "LinkMeUpAppDelegate.h"

#import "myLogInViewController.h"
#import "mySignUpViewController.h"
#import "pushNotifViewController.h"

#import "inboxViewController.h"
#import "friendsViewController.h"

@interface DefaultSettingsViewController ()

@end

@implementation DefaultSettingsViewController



#pragma mark - Application launch methods

- (void)launchLogIn
{
    [self presentViewController:self.myLogIn animated:YES completion:nil];
}

- (void)launchApplication:(ApplicationLaunch)launchType
{
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // add user channel to current installation (if not already added)
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:[NSString stringWithFormat:@"user_%@", [PFUser currentUser].objectId] forKey:@"channels"];
    [currentInstallation saveInBackground];
    
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
            [user deleteInBackground];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"User logged out" object:nil];
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
            [user deleteInBackground];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"User logged out" object:nil];
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
        [self launchApplication: kApplicationLaunchReturning];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - FBLogInMethods

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

#pragma mark - PFLogInViewControllerDelegate

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
    NSLog(@"logInVC didLogInUser");
    
    PFUser *me = [PFUser currentUser];
    if (me.isNew && [PFFacebookUtils isLinkedWithUser:(PFUser *)user]) // new account via Facebook
    {
        verificationViewController *vvc = [[verificationViewController alloc] init];
        
        // set NSUserDefault statuses
        [self setVerificationAndLaunchStatuses];
        
        // set mobile verification status in Parse
        me[@"mobileVerified"] = [NSNumber numberWithBool:NO];
        
        // get the user's data from Facebook
        [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *fbUser, NSError *error) {
            
            // critical info
            NSString *oldUsername = me.username;
            me.username = [fbUser objectForKey:@"email"];
            me.email = [fbUser objectForKey:@"email"];
            me[@"facebook_id"] = [fbUser objectForKey:@"id"];
            me[@"name"] = [NSString stringWithFormat:@"%@ %@", fbUser.first_name, fbUser.last_name];

            // supplemental info
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
                        me[@"facebook_email"] = [fbUser objectForKey:@"email"];
                        me[@"name"] = [NSString stringWithFormat:@"%@ %@", fbUser.first_name, fbUser.last_name];
                        me[@"first_name"] = fbUser.first_name;
                        
                        [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                           
                            if (error)
                            {
                                NSLog(@"Error saving user info to Parse (after discovering existing account with email) %@ %@", error, [error userInfo]);
                            }
                            
                        }];
                    }
                }
                
            }];

        }];
        
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
    NSLog(@"Failed to log in...");
    
    // Internal server error || Failed to initialize mongo connection
    if (error.code == 1 || error.code == 159)
    {
        [[[UIAlertView alloc] initWithTitle:@"Server Issues"
                                    message:@"We're sorry, but we're experiencing server issues :( \nPlease try again in a bit."
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

#pragma mark - PFSignUpViewControllerDelegate

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
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you fill out all of the information!"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    
    if (!passwordSecure)
    {
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
    mySignUpViewController *mySignUp = (mySignUpViewController *)signUpController;
    mySignUp.verificationVC = [[verificationViewController alloc] init];
    
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
    NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController
{
    NSLog(@"User dismissed the signUpViewController");
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
