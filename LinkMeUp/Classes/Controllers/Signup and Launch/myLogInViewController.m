//
//  myLogInViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 6/20/14.
//
//

#import "myLogInViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <Parse/PFLogInViewController.h>
#import <Parse/PFSignUpViewController.h>

#import "Constants.h"

@interface myLogInViewController ()

@end

@implementation myLogInViewController


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

    // set logo
    UILabel *logo = [Constants createLogoLabel];
    [self.logInView setLogo:logo];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self.logInView.logo setFrame:CGRectMake((self.logInView.bounds.size.width - 200.0f)/2, (IS_IPHONE_5 ? 100.0f : 60.0f), 200.0f, 50.0f)];
    
    if (IS_IPHONE_5)
    {
        /*// add background to cover white margin on bottom
        UIImageView *grayBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
        [self.view addSubview:grayBackground];
        [self.view sendSubviewToBack:grayBackground];
        grayBackground.opaque = YES;
        
        // center view in screen
        self.logInView.transform = CGAffineTransformTranslate(self.logInView.transform, 0.0f, -50.0f);
        self.logInView.dismissButton.frame = CGRectMake(3.0f, 75.0f, 25.0f, 25.0f);*/
        
        UIView *fieldsBackground = self.logInView.subviews[1];
        fieldsBackground.transform = CGAffineTransformTranslate(fieldsBackground.transform, 0.0f, -50.0f);
        
        self.logInView.usernameField.transform = CGAffineTransformTranslate(self.logInView.usernameField.transform, 0.0f, -50.0f);
        self.logInView.passwordField.transform = CGAffineTransformTranslate(self.logInView.passwordField.transform, 0.0f, -50.0f);
        
        self.logInView.logInButton.transform = CGAffineTransformTranslate(self.logInView.logInButton.transform, 0.0f, -50.0f);
        self.logInView.passwordForgottenButton.transform = CGAffineTransformTranslate(self.logInView.passwordForgottenButton.transform, 0.0f, -50.0f);
        
        self.logInView.facebookButton.transform = CGAffineTransformTranslate(self.logInView.facebookButton.transform, 0.0f, -50.0f);
        self.logInView.externalLogInLabel.transform = CGAffineTransformTranslate(self.logInView.externalLogInLabel.transform, 0.0f, -50.0f);
        
        self.logInView.signUpButton.transform = CGAffineTransformTranslate(self.logInView.signUpButton.transform, 0.0f, -50.0f);
        self.logInView.signUpLabel.transform = CGAffineTransformTranslate(self.logInView.signUpLabel.transform, 0.0f, -50.0f);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
