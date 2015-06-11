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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // did user finish signing up?
    NSNumber *userUnverified = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_unverified", [PFUser currentUser].objectId]];
    
    if (![PFUser currentUser] || [userUnverified boolValue] == YES) // No user logged in OR user terminated sign up process
    {
        if ([userUnverified boolValue] == YES)
        {
            // user account terminated
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@_unverified", [PFUser currentUser].objectId]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // delete user
            [[PFUser currentUser] deleteInBackground];
        }
        
        //NSLog(@"NSUserDefaults %@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
        
        // Create the log in view controller
        self.myLogIn = [[myLogInViewController alloc] init];
        [self.myLogIn setDelegate:self]; // Set ourselves as the delegate
        
        // Set FB permissions
        NSArray *permissionsArray = @[@"public_profile", @"user_friends", @"email"];
        [self.myLogIn setFacebookPermissions:permissionsArray];
        self.myLogIn.fields = (PFLogInFields)(PFLogInFieldsDefault | PFLogInFieldsFacebook);
        
        // Create the sign up view controller
        mySignUpViewController *signUpViewController = [[mySignUpViewController alloc] init];
        //signUpViewController.fields = (PFSignUpFields)(PFSignUpFieldsUsernameAndPassword |PFSignUpFieldsSignUpButton | PFSignUpFieldsDismissButton);
        [signUpViewController setDelegate:self]; // Set ourselves as the delegate
        
        // Assign our sign up controller to be displayed from the login controller
        [self.myLogIn setSignUpController:signUpViewController];
        
        // Present the log in view controller
        [self launchLogIn];
    }

    else if ([PFUser currentUser].isNew) // new user
    {
        // create status label
        [self createStatusLabel];
        
        PFUser *user = [PFUser currentUser];
        
        // new account is a facebook account (created through "login with facebook" option)
        if ([PFFacebookUtils isLinkedWithUser:(PFUser *)user] && (user.email == NULL))
        {
            // show loading status...
            [self setLoadingLabel];
            
            // get the user's data from Facebook
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *fbUser, NSError *error)
             {
                 // check and see if a user already exists for this email
                 PFQuery *query = [PFUser query];
                 [query whereKey:@"email" equalTo:[fbUser objectForKey:@"email"]];
                 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                     
                     if (objects == nil | [objects count] == 0) // no existing LMU account -- new user!
                     {
                         NSLog(@"No existing LMU account found");
                         
                         // critical info
                         user.username = [fbUser objectForKey:@"email"];
                         user.email = [fbUser objectForKey:@"email"];
                         user[@"facebook_id"] = [fbUser objectForKey:@"id"];
                         user[@"name"] = [NSString stringWithFormat:@"%@ %@", fbUser.first_name, fbUser.last_name];
                         
                         // supplemental info
                         user[@"first_name"] = fbUser.first_name;
                         
                         [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                             if (!error)
                             {
                                 NSLog(@"Now welcoming");
                                 [self setWelcomeLabelForUser: fbUser.first_name];
                                 [self launchApplication: kApplicationLaunchNew];
                             }
                             else
                             {
                                 NSLog(@"Error saving user information %@ %@", error, [error localizedDescription]);
                             }
                         }];
                     }
                     
                     for (PFObject *object in objects) // existing accounts (w/same email) found
                     {
                         PFUser *existingUser = (PFUser *)object;
                         
                         // existing account (w/same email) found
                         // (besides FB account just created)
                         if (![PFFacebookUtils isLinkedWithUser:(PFUser *)existingUser])
                         {
                             NSLog(@"It seems like you already have a LinkMeUp account.");
                             NSLog(@"Please log in, and then go to your Profile to link your account to Facebook.");
                             
                             [[[UIAlertView alloc] initWithTitle:@"Existing account"
                                                         message:@"To enable login with facebook, please sign in, go to Friends, and link your account with Facebook."
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil] show];
                             
                             [user deleteInBackground];
                             
                             // put the user logged out notification on the wire
                             [[NSNotificationCenter defaultCenter] postNotificationName:@"User logged out" object:nil];
                             [[FBSession activeSession] closeAndClearTokenInformation];
                             
                             // Present the log in view controller
                             self.myLogIn.fields = (PFLogInFields)(PFLogInFieldsDefault);
                             [self launchLogIn];
                         }
                         
                         // existing FB-linked account (w/same email) found
                         // shouldn't happen
                         else
                         {
                         }
                     }
                 }];
             }];
        }
        
        else // new account is a LMU account
        {
            NSLog(@"New LMU account");
            [self setWelcomeLabelForUser:user.username];
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
    NSLog(@"Logged in");
    
    if ([PFUser currentUser].isNew) // new account via Facebook
    {
        verificationViewController *vvc = [[verificationViewController alloc] init];
        
        // user began sign up process
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:[NSString stringWithFormat:@"%@_unverified", [PFUser currentUser].objectId]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSLog(@"NSUserDefaults: %@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
        
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
    
    // user began sign up process
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:[NSString stringWithFormat:@"%@_unverified", [PFUser currentUser].objectId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"NSUserDefaults: %@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    
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

#pragma mark - UI helper methods

- (void)createStatusLabel
{
    // to avoid label pileup
    // Q: in what cases could this happen?
    [self.statusLabel removeFromSuperview];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 300.0f)/2, 210.0f, 300.0f, 40.0f)];
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
