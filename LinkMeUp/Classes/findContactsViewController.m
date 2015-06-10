//
//  connectWithFriendsViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 12/13/14.
//
//

#import "findContactsViewController.h"

#import "LinkMeUpAppDelegate.h"

#import "Constants.h"

@interface findContactsViewController ()

@end

@implementation findContactsViewController


#pragma mark - View controller lifecycle

- (void)viewDidLoad
{
    // enable continue button
    [Constants enableButton:self.continueButton];
    
    // display skip option
    // [self displaySkipLabel];
    
    // add link with Facebook button
    // [self.view addSubview:[self createFacebookButton]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI action methods

- (IBAction)continuePressed:(id)sender
{
    // ask for address book permission
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (granted)
                   NSLog(@"Address book access permission granted");
                
                else NSLog(@"Address book access permission denied");
                    
                [self returnAndLaunch];
                
            });
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied)
    {
        NSString *alertTitle = @"Enable Contacts Access";
        NSString *alertMessage = @"Please go to Settings -> Privacy -> Contacts and toggle permissions for LinkMeUp to On.";
        
        if (IS_IOS8)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style: UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                [self returnAndLaunch];
            }];
            
            [alert addAction: defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:alertTitle
                                        message:alertMessage
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
        
    }
    else // kABAuthorizationStatusAuthorized
    {
        [self returnAndLaunch];
    }
}

// user chose to link account with FB
- (IBAction)didLinkWithFB:(id)sender
{
    NSLog(@"Linking accounts...");
    
    __block BOOL shouldLaunch = NO;
    
    PFUser *me = [PFUser currentUser];
    [PFFacebookUtils linkUser:me
                  permissions:@[ @"public_profile", @"user_friends", @"email"]
                        block:^(BOOL succeeded, NSError *error) {
        if (!error)
        {
            // get the user's data from Facebook
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *fbUser, NSError *error)
             {
                 NSLog(@"Linked your facebook account!");
                 
                 // critical info
                 me[@"facebook_id"] = fbUser.objectID;
                 me[@"name"] = [[fbUser.first_name stringByAppendingString:@" "] stringByAppendingString:fbUser.last_name];
                 
                 // supplemental info
                 me[@"first_name"] = fbUser.first_name;
                 me[@"facebook_email"] = [fbUser objectForKey:@"email"];;
                 
                 [me saveInBackground];
             }];
                                  
            shouldLaunch = YES;
        }
        
        else
        {
            NSLog(@"Error linking accounts %@ %@", error, [error userInfo]);
            
            if ([[[error userInfo] objectForKey:@"code"] isEqualToNumber:@208])
            {
                NSString *message = @"Another user is already linked to this facebook id.";
                [[[UIAlertView alloc] initWithTitle:@"Already linked"
                                            message:message
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil, nil] show];
            }
            else
            {
                shouldLaunch = YES;
            }
        }
        
        if (shouldLaunch)
        {
            [self returnAndLaunch];
        }
    }];
}

- (void)skipLabelPressed:(id)sender
{
    [self returnAndLaunch];
}

- (void)returnAndLaunch
{
    // climb up through presenting view controller hierarchy...
    PFUser *user = [PFUser currentUser];
    
    if ([PFFacebookUtils isLinkedWithUser:(PFUser *)user] && (user.email == NULL))
    {
        verificationViewController *verify = (verificationViewController *) self.presentingViewController;
        myLogInViewController *logIn = (myLogInViewController *) verify.presentingViewController;
        DefaultSettingsViewController *defaultSettings = (DefaultSettingsViewController *) logIn.presentingViewController;
        
        [defaultSettings dismissViewControllerAnimated:YES completion:nil];
    }
    
    else if (user.isNew) // new user, but not created via Facebook
    {
        verificationViewController *verify = (verificationViewController *) self.presentingViewController;
        mySignUpViewController *signUp = (mySignUpViewController *) verify.presentingViewController;
        myLogInViewController *logIn = (myLogInViewController *) signUp.presentingViewController;
        DefaultSettingsViewController *defaultSettings = (DefaultSettingsViewController *) logIn.presentingViewController;
        
        [defaultSettings dismissViewControllerAnimated:YES completion:nil];
    }
    
    else // exisiting user
    {
        UIViewController *presenting = self.presentingViewController;
        if ([presenting isKindOfClass:[verificationViewController class]])
        {
            verificationViewController *verify = (verificationViewController *) presenting;
            UIViewController *presentingPresenting = verify.presentingViewController;
            
            [presentingPresenting dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [presenting dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // only one option
    [self returnAndLaunch];
}

#pragma mark - UI helper methods

- (void)displaySkipLabel
{
    if (!self.skipLabel)
        self.skipLabel = [[UILabel alloc] initWithFrame:CGRectMake(178.0f, 36.0f, 128.0f, 29.0f)];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentRight;
    
    self.skipLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:(@"Skip")
                                                                           attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                          NSFontAttributeName: GILL_20,
                                                                                          NSForegroundColorAttributeName: WHITE_LIME}];
    
    // go back link
    UITapGestureRecognizer *linkPressed = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(skipLabelPressed:)];
    linkPressed.delegate = self;
    linkPressed.numberOfTapsRequired = 1;
    linkPressed.cancelsTouchesInView = NO;
    
    self.skipLabel.userInteractionEnabled = YES;
    [self.skipLabel addGestureRecognizer:linkPressed];
    
    [self.view addSubview:self.skipLabel];
}

- (UIButton *)createFacebookButton
{
    UIButton *linkWithFB = [UIButton buttonWithType:UIButtonTypeCustom];
    [linkWithFB setFrame:CGRectMake(45.0f, 313.0f, 230.0f, 65.5f)]; // centered in cell
    
    [linkWithFB setBackgroundImage:[UIImage imageNamed:@"login-button-small"] forState:UIControlStateNormal];
    [linkWithFB setBackgroundImage:[UIImage imageNamed:@"login-button-small-pressed"] forState:UIControlStateSelected];
    
    linkWithFB.titleLabel.font = HELV_16;
    
    [linkWithFB setTitle:@"            Find Friends" forState:UIControlStateNormal];
    [linkWithFB setTitle:@"            Find Friends" forState:UIControlStateSelected];
    
    [linkWithFB addTarget:self action:@selector(didLinkWithFB:) forControlEvents:UIControlEventTouchUpInside];
    
    return linkWithFB;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
