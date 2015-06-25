//
//  pushNotifViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 6/8/15.
//
//

#import "pushNotifViewController.h"

#import "LinkMeUpAppDelegate.h"

#import "Constants.h"



@interface pushNotifViewController ()

@end

@implementation pushNotifViewController


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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRegister)
                                                     name:kDidRegisterForPush object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFailToRegister)
                                                     name:kDidFailToRegisterForPush object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dismissAndReturn)
                                                     name:kUserRespondedToPushNotifAlertView object:nil];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // enable button
    [Constants enableButton: self.continueButton];
    
    // add screenshot
    UIImage *image = [UIImage imageNamed:@"PushNotifBadge.jpg"];
    CGFloat aspectRatio = image.size.height / image.size.width;
    
    // set image width
    CGFloat imageWidth;
    if (IS_IPHONE_5)
    {
        NSLog(@"iPhone >= 5");
        imageWidth = self.view.frame.size.width / 1.31;
    }
    else
    {
        NSLog(@"iPhone 4");
        imageWidth = self.view.frame.size.width / 1.55;
    }
    
    // image position
    CGFloat textEnd = self.lastTextLine.frame.origin.y + self.lastTextLine.frame.size.height;
    CGFloat buffer = 30;
    
    // image container
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - imageWidth)/2,  textEnd + buffer, imageWidth, imageWidth * aspectRatio)];
    [self.imageView setImage:image];
    
    // add image
    [self.view addSubview: self.imageView];
    [self.view sendSubviewToBack: self.imageView];
    
    // initialize alert views
    NSString *alertTitle = @"Enable Push Notifications";
    NSString *alertMessage = [NSString stringWithFormat: @"\nPlease go to Settings \u2192 Notification Center \u2192 LinkMeUp.\n\n Then select Banners and toggle \"Badge App Icon\" to On."];
    
    if (IS_IOS8)
    {
        self.alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                style: UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  [self dismissAndReturn];
                                                              }];
        
        [self.alertController addAction: defaultAction];
    }
    else
    {
        self.alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                    message:alertMessage
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // set didShowPushVCThisSession to YES
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey: kDidShowPushVCThisSession];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // clear timer
    [self.didPresentTimer invalidate];
    self.didPresentTimer = nil;
    
    // set delegate to nil
    self.alertView.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    // clear NSUserDefault flags
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDidAttemptToRegisterForPushNotif];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDidPresentPushNotifAlertView];
    
    // unsubscribe from notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDidRegisterForPush object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDidFailToRegisterForPush object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserRespondedToPushNotifAlertView object:nil];
}

#pragma mark - NSTimer methods

- (void)checkAlertViewStatus
{
    NSLog(@"Checking alert view status");
    
    // if haven't presented default alert view, present custom alert view
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:kDidPresentPushNotifAlertView] boolValue])
    {
        NSLog(@"Haven't presented default");
        
        [self.didPresentTimer invalidate];
        self.didPresentTimer = nil;
        
        [self presentCustomAlertView];
    }
}

#pragma mark - Notification methods

- (void)didRegister
{

}

- (void)didFailToRegister
{

}

- (void)dismissAndReturn
{
    NSLog(@"Dismiss and return called");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UI action methods

- (IBAction)continuePressed:(id)sender
{
    if ([self.sharedData.me[kNumberPushRequests] integerValue] > 0)
    {
        NSLog(@"Push Requests Case 1 - Custom Alert View");
        
        // update numberPushRequests field
        NSInteger oldValue = [self.sharedData.me[kNumberPushRequests] integerValue];
        self.sharedData.me[kNumberPushRequests] = [NSNumber numberWithInteger:(oldValue + 1)];
        [self.sharedData.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error)
            {
                NSLog(@"Error saving numberPushRequests state to Parse %@ %@", error, [error userInfo]);
            }
        }];

        [self presentCustomAlertView];
    }
    else
    {
        NSLog(@"Push Requests Case 2 - Requesting System Permissions");
        
        // update numberPushRequests field
        self.sharedData.me[kNumberPushRequests] = [NSNumber numberWithInt: 1];
        [self.sharedData.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error)
            {
                NSLog(@"Error saving numberPushRequests state to Parse %@ %@", error, [error userInfo]);
            }
        }];
        
        // register for push notifications
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
        {
            // iOS 8 Notifications
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
            
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
        else
        {
            // iOS <8 Notifications
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
             (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
        }
        
        // listens for user response to push notif alert view
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey: kDidAttemptToRegisterForPushNotif];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // present custom alert view if default (Apple's) alert view isn't being presented
        self.didPresentTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                                target:self
                                                              selector:@selector(checkAlertViewStatus)
                                                              userInfo:nil
                                                               repeats:NO];
    }
}

- (void)presentCustomAlertView
{
    NSLog(@"Presenting alert view");
    
    if (IS_IOS8)
    {
        [self presentViewController:self.alertController animated:YES completion:nil];
    }
    else
    {
        [self.alertView show];
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // only one option
    [self dismissAndReturn];
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
