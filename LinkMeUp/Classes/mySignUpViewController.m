//
//  mySignUpViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/6/14.
//
//

#import "mySignUpViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "Constants.h"

#import <Parse/PFLogInViewController.h>
#import <Parse/PFSignUpViewController.h>

#import "legalInfoViewController.h"

@interface mySignUpViewController ()

@end

@implementation mySignUpViewController


#pragma mark - Tap gesture delegate

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    // touch in view
    CGPoint touchPoint = [sender locationInView:self.legalLabel];
    //NSLog(@"Touch %@", NSStringFromCGPoint(touchPoint));
    
    CGRect termsRect = CGRectMake(25.0f, 40.0f, 70.0f, 25.0f);
    CGRect privacyRect = CGRectMake(130.0f, 60.0f, 90.0f, 25.0f);
    
    if (CGRectContainsPoint(termsRect, touchPoint))
    {
        //NSLog(@"Terms of Use clicked");
        
        legalInfoViewController *livc = [[legalInfoViewController alloc] init];
        livc.legalInfo = kLegalInfoTerms;
        livc.wasPushed = NO;
        [self presentViewController:livc animated:YES completion:nil];
    }
    
    if (CGRectContainsPoint(privacyRect, touchPoint))
    {
        //NSLog(@"Privacy policy clicked");
        
        legalInfoViewController *livc = [[legalInfoViewController alloc] init];
        livc.legalInfo = kLegalInfoPrivacy;
        livc.wasPushed = NO;
        [self presentViewController:livc animated:YES completion:nil];
    }
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
    // Do any additional setup after loading the view.
    
    // set logo
    UILabel *logo = [Constants createLogoLabel];
    [self.signUpView setLogo:logo];
    
    // display legal label
    [self displayLegalLabel];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // move contents up
    [self.signUpView.logo setFrame:CGRectMake((self.signUpView.bounds.size.width - 200.0f)/2, (IS_IPHONE5 ? 90.0f : 75.0f), 200.0f, 50.0f)];
    
    CGFloat distance = (IS_IPHONE5 ? -60.0f : -30.0f);
    
    UIView *fieldsBackground = self.signUpView.subviews[0];
    fieldsBackground.transform = CGAffineTransformTranslate(fieldsBackground.transform, 0.0f, distance);
    self.signUpView.usernameField.transform = CGAffineTransformTranslate(self.signUpView.usernameField.transform, 0.0f, distance);
    self.signUpView.passwordField.transform = CGAffineTransformTranslate(self.signUpView.passwordField.transform, 0.0f, distance);
    self.signUpView.emailField.transform = CGAffineTransformTranslate(self.signUpView.emailField.transform, 0.0f, distance);
    self.signUpView.signUpButton.transform = CGAffineTransformTranslate(self.signUpView.signUpButton.transform, 0.0f, distance);
    //self.signUpView.dismissButton.frame = CGRectMake(3.0f, 25.0f, 25.0f, 25.0f);
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

#pragma mark - Legal label

- (void)displayLegalLabel
{
    // create legal label
    if (!self.legalLabel)
        self.legalLabel = [[UILabel alloc] initWithFrame:CGRectMake(35.0f, (IS_IPHONE5 ? 340.0f: 320.0f), 250.0f, 100.0f)];
    
    self.legalLabel.numberOfLines = 0;
    self.legalLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSMutableAttributedString *termsText = [[NSMutableAttributedString alloc] initWithString: @"By creating an account, you agree to the Terms of Use "
                                                                                                "and you acknowledge that you have read the Privacy Policy."
                                                                                  attributes: @{NSParagraphStyleAttributeName: paragraphStyle,
                                                                                                NSFontAttributeName: GILL_14,
                                                                                                NSForegroundColorAttributeName: FAINT_GRAY}];
    
    // highlight Terms of Use and Privacy policy
    NSRange termsRange = NSMakeRange(41, @"Terms of Use".length);       // Terms
    NSRange privacyRange = NSMakeRange(97, @"Privacy Policy".length);   // Privacy
    
    [termsText addAttribute:NSForegroundColorAttributeName value:BLUE_200 range:termsRange];
    [termsText addAttribute:NSForegroundColorAttributeName value:BLUE_200 range:privacyRange];
    
    [self.legalLabel setAttributedText:termsText];
    
    // handle clicks on Terms of Use and Privacy Policy
    UITapGestureRecognizer *linkPressed = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    linkPressed.delegate = self;
    linkPressed.numberOfTapsRequired = 1;
    linkPressed.cancelsTouchesInView = NO;
    
    self.legalLabel.userInteractionEnabled = YES;
    [self.legalLabel addGestureRecognizer:linkPressed];
    
    // add legal label to signUpView
    [self.signUpView addSubview: self.legalLabel];
}

@end
