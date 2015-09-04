//
//  messageViewController.m
//  echoprint
//
//  Created by Samvit Jain on 6/12/14.
//
//

#import "messageViewController.h"

#import "echoprintViewController.h"
#import "contactsViewController.h"

@interface messageViewController ()

@end

@implementation messageViewController


#pragma mark - Data initialization

- (Data *)sharedData
{
    if (!_sharedData)
    {
        echoprintAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        _sharedData = appDelegate.myData;
        return _sharedData;
    }
    
    else return _sharedData;
}

#pragma mark - Swipe gestures

- (IBAction)swipeRight:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UI action methods

- (IBAction)sendTo:(id)sender
{
    if (!self.cvc)
        self.cvc = [[contactsViewController alloc] init];
    
    self.sharedData.annotation = self.textBox.text;
    
    [self.navigationController pushViewController:self.cvc animated:YES];
}

#pragma mark - Text view dismissal methods

- (IBAction)dismissKeyboardOnTap:(id)sender
{
    [[self view] endEditing:YES];
}


- (void)textViewDidBeginEditing:(UITextView *)textView
{
    textView.text = @"";
}

#pragma mark - Text view delegate methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark - Application lifecycle

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
    
    self.textBox.delegate = self;
    
    NSMutableAttributedString *firstLabel = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat: @"%@", self.sharedData.iTunesTitle]];
    
    NSMutableAttributedString *secondLabel = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat: @"by %@", self.sharedData.iTunesArtist]];
    
    self.titleLabel.attributedText = firstLabel;
    self.artistLabel.attributedText = secondLabel;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
