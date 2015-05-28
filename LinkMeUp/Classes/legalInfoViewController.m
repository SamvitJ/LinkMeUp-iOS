//
//  legalInfoViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 9/2/14.
//
//

#import "legalInfoViewController.h"

@interface legalInfoViewController ()

@end

@implementation legalInfoViewController


#pragma mark - Swipe gestures

- (IBAction)swipeRight:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UI action methods

- (void)backButtonPressed:(id)sender
{
    if (self.wasPushed)
        [self.navigationController popViewControllerAnimated:YES];
    
    else [self dismissViewControllerAnimated:YES completion:nil];
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
    
    // add back button
    UIButton *backButton = [Constants createBackButtonWithText:@"Back"];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:backButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.headerLabel.textColor = WHITE_LIME;
    self.headerLabel.font = GILL_20;
    self.headerLabel.textAlignment = NSTextAlignmentRight;
    
    NSURL *fileURL; // legal text file URL
    
    if (self.legalInfo == kLegalInfoTerms)
    {
        self.headerLabel.text = @"Terms of Use";
        fileURL = [[NSBundle mainBundle] URLForResource:@"Terms of Use" withExtension:@"rtf"];
    }
    
    else if (self.legalInfo == kLegalInfoPrivacy)
    {
        self.headerLabel.text = @"Privacy Policy";
        fileURL = [[NSBundle mainBundle] URLForResource:@"Privacy Policy" withExtension:@"rtf"];
    }
    
    else if (self.legalInfo == kLegalInfoCredits)
    {
        self.headerLabel.text = @"Credits";
        fileURL = [[NSBundle mainBundle] URLForResource:@"Credits" withExtension:@"rtf"];
    }
    
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithFileURL:fileURL options:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType} documentAttributes:nil error:nil];
    
    self.legalText.attributedText = textStorage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
