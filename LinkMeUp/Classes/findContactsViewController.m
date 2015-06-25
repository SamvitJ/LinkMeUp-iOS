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


#pragma mark - Data initialization

- (Data *)sharedData
{
    if (!_sharedData)
    {
        LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
        _sharedData = appDelegate.myData;
        return _sharedData;
    }
    
    else return _sharedData;
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad
{
    // enable continue button
    [Constants enableButton:self.continueButton];
    
    // display skip option
    // [self displaySkipLabel];
    
    // add link with Facebook button
    // [self.view addSubview:[self createFacebookButton]];
    
    // add screenshot
    UIImage *image;
    CGFloat aspectRatio;
    CGFloat imageWidth;
    
    if (IS_IPHONE_5)
    {
        NSLog(@"iPhone >= 5");
        image = [UIImage imageNamed:@"AddressBook5.jpg"];
        
        aspectRatio = image.size.height / image.size.width;
        imageWidth = self.view.frame.size.width / 1.55;
    }
    else
    {
        NSLog(@"iPhone 4");
        image = [UIImage imageNamed:@"AddressBook4.jpg"];
        
        aspectRatio = image.size.height / image.size.width;
        imageWidth = self.view.frame.size.width / 1.90;
    }
    
    // image position
    CGFloat textEnd = self.lastLine.frame.origin.y + self.lastLine.frame.size.height;
    CGFloat buffer = 25;
    
    // image container
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - imageWidth)/2,  textEnd + buffer, imageWidth, imageWidth * aspectRatio)];
    [self.imageView setImage:image];
    
    [self.imageView.layer setBorderColor: [[UIColor lightGrayColor] CGColor]];
    [self.imageView.layer setBorderWidth: 1.0];
    
    // add image
    [self.view addSubview: self.imageView];
    [self.view sendSubviewToBack: self.imageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI action methods

- (IBAction)continuePressed:(id)sender
{
    // update numberABRequests field
    UIViewController *presenting = self.presentingViewController;
    if ([presenting isKindOfClass:[verificationViewController class]]) // presented in sign up flow
    {
        NSLog(@"Continue pressed - verification");
        
        // presented in sign up flow
        PFUser *me = [PFUser currentUser];
        me[kNumberABRequests] = [NSNumber numberWithInt: 1];
        [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error)
            {
                NSLog(@"Error saving numberABRequests state to Parse %@ %@", error, [error userInfo]);
            }
        }];
    }
    else // presented by friendsVC on contactsVC, after connections have loaded (and shared data has been initialized)
    {
        NSLog(@"Continue pressed - friends/contacts VC");
        
        if ([self.sharedData.me[kNumberABRequests] integerValue] > 0)
        {
            NSInteger oldValue = [self.sharedData.me[kNumberABRequests] integerValue];
            self.sharedData.me[kNumberABRequests] = [NSNumber numberWithInteger:(oldValue + 1)];
            [self.sharedData.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error)
                {
                    NSLog(@"Error saving numberABRequests state to Parse %@ %@", error, [error userInfo]);
                }
            }];
        }
        else
        {
            self.sharedData.me[kNumberABRequests] = [NSNumber numberWithInt: 1];
            [self.sharedData.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error)
                {
                    NSLog(@"Error saving numberABRequests state to Parse %@ %@", error, [error userInfo]);
                }
            }];
        }
    }
    
    // ask for address book permission
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (granted)
                {
                   NSLog(@"Address book access permission granted");
                
                   // if existing (V1) user, update addr book status and reload suggestions
                   PFUser *me = [PFUser currentUser];
                   if (!me.isNew)
                   {
                       [self.sharedData updateAddressBookStatus];
                       [self.sharedData loadConnections];
                   }
                }
                
                else
                {
                   NSLog(@"Address book access permission denied");
                }
                    
                [self returnAndLaunch];
                
            });
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied)
    {
        NSString *alertTitle = @"Enable Contacts Access";
        NSString *alertMessage = [NSString stringWithFormat: @"\nPlease go to Setting \u2192 Privacy \u2192 Contacts.\n\n Toggle slider for LinkMeUp to On, and then restart LinkMeUp."];
        
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
    else // kABAuthorizationStatusAuthorized - shouldn't happen
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
    
    UIViewController *presenting = self.presentingViewController;
    if ([presenting isKindOfClass:[verificationViewController class]])
    {
        NSLog(@"Return and launch - verification");
        
        if ([PFFacebookUtils isLinkedWithUser:(PFUser *)user] && (user.email == NULL)) // new user, created via FB login
        {
            verificationViewController *verify = (verificationViewController *) presenting;
            myLogInViewController *logIn = (myLogInViewController *) verify.presentingViewController;
            DefaultSettingsViewController *defaultSettings = (DefaultSettingsViewController *) logIn.presentingViewController;
            
            [defaultSettings dismissViewControllerAnimated:YES completion:nil];
        }
        
        else if (user.isNew) // new user, but not created via Facebook
        {
            verificationViewController *verify = (verificationViewController *) presenting;
            mySignUpViewController *signUp = (mySignUpViewController *) verify.presentingViewController;
            myLogInViewController *logIn = (myLogInViewController *) signUp.presentingViewController;
            DefaultSettingsViewController *defaultSettings = (DefaultSettingsViewController *) logIn.presentingViewController;
            
            [defaultSettings dismissViewControllerAnimated:YES completion:nil];
        }
        
        else // V1 user who previously denied address book permissions - case not currently reachable
        {
            // update authorization status
            [self.sharedData updateAddressBookStatus];
            
            verificationViewController *verify = (verificationViewController *) presenting;
            UIViewController *presentingPresenting = verify.presentingViewController;
            
            [presentingPresenting dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else // existing user
    {
        NSLog(@"Return and launch - other");
        
        // update authorization status - not determined -> denied OR not determined -> accepted (redundant)
        [self.sharedData updateAddressBookStatus];
        
        UIViewController *presenting = self.presentingViewController;
        [presenting dismissViewControllerAnimated:YES completion:nil];
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
