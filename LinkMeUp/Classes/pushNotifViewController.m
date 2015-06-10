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
    UIImage *image = [UIImage imageNamed:@"PushNotifShort.jpg"];
    CGFloat aspectRatio = image.size.height / image.size.width;
    
    // set image width
    CGFloat imageWidth;
    if (IS_IPHONE_5)
    {
        NSLog(@"iPhone >= 5");
        imageWidth = self.view.frame.size.width / 1.32;
    }
    /*else if (IS_IPHONE_6P) 
    {
        NSLog(@"iPhone 6 Plus");
        imageWidth = self.view.frame.size.width / 1.2;
    }
    else if (IS_IPHONE_6) 
    {
        NSLog(@"iPhone 6");
        imageWidth = self.view.frame.size.width / 1.3;
    }*/
    else
    {
        NSLog(@"iPhone 4");
        imageWidth = self.view.frame.size.width / 1.5;
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
    
    // set did ask push to YES
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey: kDidAskPushThisSession];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"%@ push notif VC", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    // unsubscribe from notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDidRegisterForPush object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDidFailToRegisterForPush object:nil];
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
        NSLog(@"Case 1");
        
        // update numberPushRequests field
        int oldValue = [self.sharedData.me[kNumberPushRequests] integerValue];
        self.sharedData.me[kNumberPushRequests] = [NSNumber numberWithInt:(oldValue + 1)];
        [self.sharedData.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error)
            {
                NSLog(@"Error saving numberPushRequests state to Parse %@ %@", error, [error userInfo]);
            }
        }];
        
        NSString *alertTitle = @"Enable Push Notifications";
        NSString *alertMessage = [NSString stringWithFormat: @"Please go to Settings -> Notification Center -> LinkMeUp.\n\n Then select Banners and toggle \"Badge App Icon\" to On."];
        
        if (IS_IOS8)
        {
            NSLog(@"iOS 8");
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style: UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                 [self dismissAndReturn];
            }];
            
            [alert addAction: defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            NSLog(@"iOS 7");
            
            [[[UIAlertView alloc] initWithTitle:alertTitle
                                        message:alertMessage
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
        
    }
    else
    {
        NSLog(@"Case 2");
        
        // update state
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
        
        // return to app
        [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(dismissAndReturn) userInfo:nil repeats:NO];
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
