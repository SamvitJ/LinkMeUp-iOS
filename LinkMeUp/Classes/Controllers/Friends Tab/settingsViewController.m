//
//  settingsViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 8/16/14.
//
//

#import "settingsViewController.h"

#import "LinkMeUpAppDelegate.h"

#import "Constants.h"
#import "settingsTableViewCell.h"

#import "legalInfoViewController.h"

@interface settingsViewController ()

@end

@implementation settingsViewController


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
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // set table view delegates
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // add back button
    UIButton *backButton = [Constants createBackButtonWithText:@"Back"];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:backButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    // set delegates to nil
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

#pragma mark - Swipe gestures

- (IBAction)swipeRight:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UI action methods

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 3;
        case 1:
            return 3;
        case 2:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Settings Cells";
    settingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[settingsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = GILL_18;
    }
    
    cell.textLabel.text = @"";
    cell.userInfoLabel.text = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.section)
    {
        case 0:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = @"Username";
                    cell.userInfoLabel.text = self.sharedData.me.username;
                    
                    break;
                }
                    
                case 1:
                {
                    cell.textLabel.text = @"Email";
                    cell.userInfoLabel.text = self.sharedData.me.email;
                    
                    break;
                }
                    
                case 2:
                {
                    cell.textLabel.text = @"Mobile No.";
                    cell.userInfoLabel.text = [self.sharedData.me objectForKey:@"mobile_number"];
                    
                    break;
                }
                    
                default:
                    break;
            }
            
            break;
        }
            
        case 1:
        {
            switch (indexPath.row)
            {
                case 0:
                    cell.textLabel.text = @"Terms of Use";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                    
                case 1:
                    cell.textLabel.text = @"Privacy Policy";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                    
                case 2:
                    cell.textLabel.text = @"Credits";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            break;
        }
            
        case 2:
        {
            cell.textLabel.text = @"Log Out";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        legalInfoViewController *livc = [[legalInfoViewController alloc] init];
        livc.wasPushed = YES;
        
        switch (indexPath.row)
        {
            case 0: // terms of use
            {
                livc.legalInfo = kLegalInfoTerms;
                break;
            }
                
            case 1: // privacy policy
            {
                livc.legalInfo = kLegalInfoPrivacy;
                break;
            }
                
            case 2: // credits
            {
                livc.legalInfo = kLegalInfoCredits;
                break;
            }
                
            default:
                break;
        }
        
        [self.navigationController pushViewController:livc animated:YES];
    }
    
    else if (indexPath.section == 2)
    {
        if (indexPath.row == 0)
        {
            LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
            
            UIActionSheet *logOut = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to log out?" delegate:appDelegate cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Log Out" otherButtonTitles: nil];
            
            [logOut showInView:self.view];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 5.0f, tableView.frame.size.width, 20.0f)];
    
    [label setFont:[UIFont boldSystemFontOfSize:16]];
    
    switch (section)
    {
        case 0:
            [label setText:@"My info"];
            break;
            
        case 1:
            [label setText:@"About LinkMeUp"];
            break;
            
        case 2:
            [label setText:@"Account"];
            break;
            
        default:
            break;
    }
    
    [view addSubview:label];
    [view setBackgroundColor:SECTION_HEADER_GRAY];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return FRIENDS_HEADER_HEIGHT;
}

@end
