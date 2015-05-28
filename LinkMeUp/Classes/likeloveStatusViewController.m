//
//  likeloveStatusViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 8/18/14.
//
//

#import "likeloveStatusViewController.h"

#import "reactionTableViewCell.h"

@interface likeloveStatusViewController ()

@end

@implementation likeloveStatusViewController


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
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in each section
    return [self.reactionData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Reaction cells";
    
    reactionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[reactionTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSString *receiverName = [[self.reactionData objectAtIndex:indexPath.row] objectForKey:@"name"];
    
    cell.contactLabel.text = receiverName;
    cell.dateLabel.text = [Constants dateToString:[self.reactionData[indexPath.row] objectForKey:@"time"]];
    
    return cell;
}

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 7.0f, tableView.frame.size.width - 20.0f, REPLIES_HEADER_HEIGHT - 10.0f)];
    label.font = HELV_16;
    label.textColor = [UIColor whiteColor];
    label.text = [NSString stringWithFormat:@"Friends who %@ your link", (self.reaction == kReactionLike ? @"liked" : @"loved")];
    
    [view addSubview:label];
    [view setBackgroundColor:SECTION_HEADER_GRAY];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return REPLIES_HEADER_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return REACTION_ROW_HEIGHT;
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
    
    // initialize table
    self.table.delegate = self;
    self.table.dataSource = self;
    
    // add back button
    UIButton *backButton = [Constants createBackButtonWithText:@"Link"];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:backButton];
    
    // Remove extra separators from tableview
    self.table.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.headerLabel.textColor = WHITE_LIME;
    self.headerLabel.font = GILL_20;
    self.headerLabel.textAlignment = NSTextAlignmentRight;
    self.headerLabel.text = (self.reaction == kReactionLike ? @"Likes" : @"Loves");
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
@end
