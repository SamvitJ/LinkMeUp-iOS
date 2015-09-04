//
//  optionsViewController.m
//  echoprint
//
//  Created by Samvit Jain on 7/10/14.
//
//

#import "optionsViewController.h"

#import "Constants.h"

@interface optionsViewController ()

@end

@implementation optionsViewController


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

#pragma mark - Delegate and notification methods

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    sender.cancelsTouchesInView = NO;
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        if (self.titleField.isFirstResponder)
        {
            [self.titleField resignFirstResponder];
            sender.cancelsTouchesInView = YES;
        }
        
        else if (self.artistField.isFirstResponder)
        {
            [self.artistField resignFirstResponder];
            sender.cancelsTouchesInView = YES;
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.titleField)
    {
        [textField resignFirstResponder];
        [self.artistField becomeFirstResponder];
    }
    
    else
    {
        [textField resignFirstResponder];
    }
    
    return NO;
}

#pragma mark - UI action methods

- (IBAction)continuePressed:(id)sender
{
    // user has left title AND artist fields blank
    if (self.selectedCell == kUserEnter && ([self.titleField.text isEqualToString:@""] && [self.artistField.text isEqualToString:@""]))
    {
        return;
    }
    
    // disabled songId option for now
    else if (self.selectedCell == kSongId)
    {
        return;
    }
    
    else
    {
        self.songInfoVC = [[songInfoViewController alloc] init];

        if (self.selectedCell == kUserEnter)
        {
            self.sharedData.userTitle = self.titleField.text;
            self.sharedData.userArtist = self.artistField.text;
            //self.songInfoVC.backgroundColor = BLUE_200;
        }
        
        else if (self.selectedCell == kSongId)
        {
            //self.songInfoVC.backgroundColor = SAND_50;
        }

        [self.navigationController pushViewController:self.songInfoVC animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in each section
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Song ID Options";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // default state: user enter option selected
    if (indexPath.row == kUserEnter)
    {
        cell.selected = YES;
        cell.layer.borderColor = [UIColor whiteColor].CGColor;
        cell.layer.borderWidth = 2.0f;
        cell.backgroundColor = BLUE_200;
        
        self.userEnterLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 15.0f, 290.0f, 25.0f)];
        self.userEnterLabel.font = HELV_18;
        self.userEnterLabel.textColor = [UIColor whiteColor];
        self.userEnterLabel.text = @"Enter song info   ";
        [cell addSubview:self.userEnterLabel];

        [self displayTitleFieldInCell:cell];
        [self displayArtistFieldInCell:cell];
        
        return cell;
    }
    
    else if (indexPath.row == kSongId)
    {
        cell.selected = NO;
        cell.layer.borderColor = [UIColor clearColor].CGColor;
        cell.backgroundColor = SAND_50;
        
        cell.textLabel.font = HELV_LIGHT_18;
        cell.textLabel.textColor = [UIColor darkTextColor];
        cell.textLabel.text = @"Send what I'm listening to       ";
        
        return cell;
    }
    
    else return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectedCell == kUserEnter)
    {
        if (indexPath.row == kUserEnter)
        {
            cell.alpha = 1.0;
        }
        
        else if (indexPath.row == kSongId)
        {
            cell.alpha = ALPHA_DISABLED;
        }
    }
    
    else if (self.selectedCell == kUserEnter)
    {
        if (indexPath.row == kUserEnter)
        {
            cell.alpha = ALPHA_DISABLED;
        }
        
        else if (indexPath.row == kSongId)
        {
            cell.alpha = 1.0;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.table.frame.size.height/2.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    self.selectedCell = (MessengerOptions)indexPath.row;
    
    NSIndexPath *pathForOtherCell = [NSIndexPath indexPathForRow:(1 - self.selectedCell) inSection:0];
    UITableViewCell *otherCell = [tableView cellForRowAtIndexPath:pathForOtherCell];
    
    // general settings
    selectedCell.selected = YES;
    selectedCell.layer.borderColor = [UIColor whiteColor].CGColor;
    selectedCell.layer.borderWidth = 2.0f;
    selectedCell.alpha = 1.0f;

    otherCell.selected = NO;
    otherCell.layer.borderColor = [UIColor clearColor].CGColor;
    otherCell.alpha = ALPHA_DISABLED;
    
    // specific settings
    if (indexPath.row == kUserEnter)
    {
        self.userEnterLabel.frame = CGRectMake(15.0f, 15.0f, 290.0f, 25.0f);
        self.userEnterLabel.textColor = [UIColor whiteColor];
        self.userEnterLabel.font = HELV_18;
        
        otherCell.textLabel.textColor = [UIColor darkTextColor];
        otherCell.textLabel.font = HELV_LIGHT_18;
        
        [self displayTitleFieldInCell:selectedCell];
        [self displayArtistFieldInCell:selectedCell];
    }
    
    else if (indexPath.row == kSongId)
    {
        selectedCell.textLabel.textColor = [UIColor whiteColor];
        selectedCell.textLabel.font = HELV_BOLD_18;
        
        self.userEnterLabel.frame = CGRectMake(15.0f, (otherCell.frame.size.height - 25.0f)/2, 290.0f, 25.0f); // default frame
        self.userEnterLabel.textColor = [UIColor darkTextColor];
        self.userEnterLabel.font = HELV_LIGHT_18;
        
        self.titleField.hidden = YES;
        self.artistField.hidden = YES;
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
    // Do any additional setup after loading the view from its nib.
    
    // table settings
    self.table.delegate = self;
    self.table.dataSource = self;
    self.table.scrollEnabled = NO;
    
    // exit text fields gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.sharedData.newSong)
    {
        // select user enter option on load
        self.selectedCell = kUserEnter;
        
        // enable button
        [Constants enableButton:self.continueButton];
        
        // clear text fields
        self.titleField = nil;
        self.artistField = nil;
        
        // reload table contents
        [self.table reloadData];
        
        // set status boolean
        self.sharedData.newSong = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    // set delegates to nil
    self.table.delegate = nil;
    self.table.dataSource = nil;
}

#pragma mark - UI helper methods

- (void)displayTitleFieldInCell:(UITableViewCell *)cell
{
    if (!self.titleField)
    {
        self.titleField = [[UITextField alloc] initWithFrame:CGRectMake(15.0f, 42.0f, 290.0f, 40.0f)];
        self.titleField.delegate = self;
        
        self.titleField.borderStyle = UITextBorderStyleRoundedRect;
        self.titleField.placeholder = @"Title";
        self.titleField.backgroundColor = [UIColor whiteColor];
        
        self.titleField.font = HELV_18;
        self.titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        //self.titleField.autocorrectionType = UITextAutocorrectionTypeNo;
        //self.titleField.spellCheckingType = UITextSpellCheckingTypeYes;
        
        [cell addSubview:self.titleField];
    }
    
    else
    {
        self.titleField.hidden = NO;
    }
}

- (void)displayArtistFieldInCell:(UITableViewCell *)cell
{
    if (!self.artistField)
    {
        self.artistField = [[UITextField alloc] initWithFrame:CGRectMake(15.0f, 82.0f, 290.0f, 40.0f)];
        self.artistField.delegate = self;
        
        self.artistField.borderStyle = UITextBorderStyleRoundedRect;
        self.artistField.placeholder = @"Artist";
        self.artistField.backgroundColor = [UIColor whiteColor];
        
        self.artistField.font = HELV_18;
        self.artistField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        //self.artistField.autocorrectionType = UITextAutocorrectionTypeNo;
        //self.artistField.spellCheckingType = UITextSpellCheckingTypeYes;
        
        [cell addSubview:self.artistField];
    }
    
    else
    {
        self.artistField.hidden = NO;
    }
}

@end

