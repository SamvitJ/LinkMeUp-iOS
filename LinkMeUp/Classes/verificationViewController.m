//
//  verificationViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/14/14.
//
//

#import "verificationViewController.h"

#import "LinkMeUpAppDelegate.h"

#import "Constants.h"

#import "DefaultSettingsViewController.h"
#import "mySignUpViewController.h"
#import "myLogInViewController.h"
#import "findContactsViewController.h"

@interface verificationViewController ()

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *code;

@end

@implementation verificationViewController

#pragma mark - UI action methods

- (IBAction)sendVerificationSMS:(id)sender
{
    // disabled button until action handled
    [Constants disableButton:self.verificationButton];
    
    if (!self.verificationScreen.window)
    {
        [self sendVerificationCode];
    }
    
    else
    {
        // Correct code entered
        if ([self.codeTextField.text isEqualToString:self.code])
        {
            // user completed verification process
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@_unverified", [PFUser currentUser].objectId]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            PFUser *me = [PFUser currentUser];
            me[@"mobile_number"] = self.phoneNumber;
            me[@"mobileVerified"] = [NSNumber numberWithBool:YES];
            
            [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error)
                {
                    NSLog(@"Error saving mobile number and verification status (true) %@ %@", error, [error userInfo]);
                }
            }];
            
            
            // remove code fields and display activity indicator
            [self.codeVerificationLabel removeFromSuperview];
            [self.codeTextField removeFromSuperview];
            [self.backLabel removeFromSuperview];
            [self.activityIndicator startAnimating];
            
            // pause
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                // display findContactsViewController
                if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
                    ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
                {
                    findContactsViewController *cwfvc = [[findContactsViewController alloc] init];
                    [self presentViewController:cwfvc animated:YES completion:nil];
                }
                else
                {
                    // climb up through presenting view controller hierarchy...
                    PFUser *user = [PFUser currentUser];
                    
                    if ([PFFacebookUtils isLinkedWithUser:(PFUser *)user] && (user.email == NULL))
                    {
                        myLogInViewController *logIn = (myLogInViewController *) self.presentingViewController;
                        DefaultSettingsViewController *defaultSettings = (DefaultSettingsViewController *) logIn.presentingViewController;
                        
                        [defaultSettings dismissViewControllerAnimated:YES completion:nil];
                    }
                    
                    else if (user.isNew) // new user, but not created via Facebook
                    {
                        mySignUpViewController *signUp = (mySignUpViewController *) self.presentingViewController;
                        myLogInViewController *logIn = (myLogInViewController *) signUp.presentingViewController;
                        DefaultSettingsViewController *defaultSettings = (DefaultSettingsViewController *) logIn.presentingViewController;
                        
                        [defaultSettings dismissViewControllerAnimated:YES completion:nil];
                    }
                    
                    else // existing user
                    {
                        UIViewController *presenting = self.presentingViewController;
                        
                        [presenting dismissViewControllerAnimated:YES completion:nil];
                    }
                }
            });
        }
        
        else
        {
            self.codeTextField.text = @"";
            
            // disable button
            [Constants disableButton:self.verificationButton];
            
            NSString *message = @"Please enter your code again";
            [[[UIAlertView alloc] initWithTitle:@"Incorrect Code"
                                        message:message
                                       delegate:nil
                              cancelButtonTitle:@"Enter again"
                              otherButtonTitles:nil, nil] show];
        }
    }
}

- (void)sendVerificationCode
{
    // transition to verification screen
    self.verificationScreen = [[UIView alloc] initWithFrame:CGRectMake(0, 77.0f, 320.0f, 270.0f)];
    self.verificationScreen.backgroundColor = [UIColor whiteColor];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.transform = CGAffineTransformMakeScale(2.0f, 2.0f);
    self.activityIndicator.center = CGPointMake(self.view.frame.size.width / 2.0, 120.0f);
    [self.activityIndicator startAnimating];
    
    [self.view addSubview: self.verificationScreen];
    [self.verificationScreen addSubview: self.activityIndicator];
    
    // remove punctuation
    self.phoneNumber = [[self.mobileNumberTextField.text componentsSeparatedByCharactersInSet:MOBILE_PUNCT_SET] componentsJoinedByString:@""];
    
    // check for existing accounts
    PFQuery *mobileNumberQuery = [PFUser query];
    [mobileNumberQuery whereKey:@"mobile_number" equalTo: self.phoneNumber];
    [mobileNumberQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] >= 5)
        {
            NSLog(@"Too many existing accounts linked to this phone number");
            
            [self.activityIndicator stopAnimating];
            [self.verificationScreen removeFromSuperview];
            
            NSString *message = @"Too many existing accounts linked to this phone number. Please sign in with an existing account.";
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:message
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil, nil] show];
        }
        
        else
        {
            // generate code
            self.code = [NSString stringWithFormat:@"%i", arc4random_uniform(999999)];
            
            // SMS info
            NSDictionary *params = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:self.phoneNumber, self.code, nil]
                                                                 forKeys:[NSArray arrayWithObjects:@"number", @"code", nil]];
            
            // send SMS
            [PFCloud callFunctionInBackground:@"inviteWithTwilio" withParameters:params block:^(id object, NSError *error) {
                if (!error)
                {
                    NSLog(@"Verification SMS sent");
                    [self.activityIndicator stopAnimating];
                    
                    [self.verificationButton setTitle:@"Verify Code                       >" forState:UIControlStateNormal];
                    [self.verificationButton setTitle:@"Verify Code                       >" forState:UIControlStateDisabled];
                    [self displayCodeVerificationLabel];
                    [self displayCodeTextField];
                    
                    // add back label
                    [self displayBackLabel];
                }
                
                else
                {
                    [self.activityIndicator stopAnimating];
                    [self.verificationScreen removeFromSuperview];
                    
                    NSString *message = @"Please enter a valid mobile number";
                    [[[UIAlertView alloc] initWithTitle:@"Error"
                                                message:message
                                               delegate:nil
                                      cancelButtonTitle:@"Ok"
                                      otherButtonTitles:nil, nil] show];
                }
            }];
        }
    }];
}

- (void)backLabelPressed:(id)sender
{
    if (self.backPressedCounter >= 3)
    {
        NSLog(@"Too many attempts");
        
        NSString *message = @"Too many verification attempts";
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:message
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil, nil] show];
        
        return;
    }
    
    // return to mobile number screen
    [self.activityIndicator stopAnimating];
    [self.verificationScreen removeFromSuperview];
    
    // increment counter
    self.backPressedCounter = self.backPressedCounter + 1;
}

#pragma mark - Delegate and notification methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (self.mobileNumberTextField.isFirstResponder)
    {
        for (int i = 0; i < [string length]; i++)
        {
            unichar c = [string characterAtIndex:i];
            
            if (![MOBILE_SET characterIsMember:c])
            {
                return NO;
            }
        }
    }
    
    if (self.codeTextField.isFirstResponder)
    {
        for (int i = 0; i < [string length]; i++)
        {
            unichar c = [string characterAtIndex:i];
            
            if (![CODE_SET characterIsMember:c])
            {
                return NO;
            }
        }
    }
    
    return YES;
}

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        if (self.mobileNumberTextField.isFirstResponder)
        {
            [self.mobileNumberTextField resignFirstResponder];
        }
        
        if (self.codeTextField.isFirstResponder)
        {
            [self.codeTextField resignFirstResponder];
        }
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // enable button
    [Constants enableButton:self.verificationButton];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return NO;
}

#pragma mark - View controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // exit text fields gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    // disable verification button
    [Constants disableButton:self.verificationButton];
    
    // initialize counter
    self.backPressedCounter = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    // display mobile number text field
    [self displayMobileNumberTextField];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI helper methods

- (void)displayMobileNumberTextField
{
    if (!self.mobileNumberTextField)
        self.mobileNumberTextField = [[UITextField alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 250.0f)/2, 183.0f, 250.0f, 34.0f)];
    
    self.mobileNumberTextField.delegate = self;
    
    self.mobileNumberTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.mobileNumberTextField.backgroundColor = FAINT_GRAY;
    self.mobileNumberTextField.layer.borderColor = [UIColor grayColor].CGColor;
    self.mobileNumberTextField.layer.borderWidth = 2.0f;
    
    self.mobileNumberTextField.placeholder = @"Mobile Number";
    self.mobileNumberTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    self.mobileNumberTextField.textAlignment = NSTextAlignmentCenter;
    self.mobileNumberTextField.font = HELV_18;
    
    [self.view addSubview:self.mobileNumberTextField];
}

- (void)displayCodeVerificationLabel
{
    if (!self.codeVerificationLabel)
        self.codeVerificationLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 290.0f)/2, 68.0f, 290.0f, 21.0f)];
  
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    self.codeVerificationLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:(@"Please enter the code you receive")
                                                                  attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                 NSFontAttributeName: [UIFont systemFontOfSize:17.0],
                                                                                 NSForegroundColorAttributeName: DARK_BLUE_GRAY}];
    
    [self.verificationScreen addSubview:self.codeVerificationLabel];
}

- (void)displayBackLabel
{
    if (!self.backLabel)
        self.backLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 290.0f)/2, 155.0f, 290.0f, 21.0f)];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    self.backLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:(@"Entered the wrong number?")
                                                                           attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                          NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                                                                          NSForegroundColorAttributeName: DARK_BLUE_GRAY}];
    
    // go back link
    UITapGestureRecognizer *linkPressed = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backLabelPressed:)];
    linkPressed.delegate = self;
    linkPressed.numberOfTapsRequired = 1;
    linkPressed.cancelsTouchesInView = NO;
    
    self.backLabel.userInteractionEnabled = YES;
    [self.backLabel addGestureRecognizer:linkPressed];
    
    [self.verificationScreen addSubview:self.backLabel];
}

- (void)displayCodeTextField
{
    if (!self.codeTextField)
        self.codeTextField = [[UITextField alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 180.0f)/2, 106.0f, 180.0f, 34.0f)];
    
    self.codeTextField.delegate = self;
    
    self.codeTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.codeTextField.backgroundColor = FAINT_GRAY;
    self.codeTextField.layer.borderColor = [UIColor grayColor].CGColor;
    self.codeTextField.layer.borderWidth = 2.0f;
    
    self.codeTextField.placeholder = @"Verification Code";
    self.codeTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    self.codeTextField.textAlignment = NSTextAlignmentCenter;
    self.codeTextField.font = HELV_18;
    
    [self.verificationScreen addSubview:self.codeTextField];
}

@end
