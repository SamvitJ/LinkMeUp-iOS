//
//  contactsViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 6/12/14.
//
//

#import "contactsViewController.h"

#import <Parse/Parse.h>

#import "Constants.h"
#import "FriendRequest.h"
#import "Link.h"

#import "inboxViewController.h"


#define SPECIAL_CASES 1 
    #define ALL_FRIENDS 0


@interface contactsViewController ()

@end

@implementation contactsViewController


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

#pragma mark - Data notification methods

- (void)didFinishLoadingFriendList
{
    if (![self.myFriends count]) // empty or nil array
    {
        // friends arrays
        self.myFriends = [[NSMutableArray alloc] init];
        self.selectedFriends = [[NSMutableArray alloc] init];
        
        // initialize friends list
        for (int i = 0; i < [self.sharedData.myFriends count]; i++)
        {
            self.myFriends[i] = self.sharedData.myFriends[i];
            self.selectedFriends[i] = @NO;
        }
        
        // status boolean
        self.allFriendsSelected = NO;
        
        // create array of buttons
        self.buttons = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < [self.myFriends count] + SPECIAL_CASES; i++)
        {
            UIButton *checkbox = [self createCheckbox];
            checkbox.tag = i;
            
            self.buttons[i] = checkbox;
        }
        
        [self.tableView reloadData];
    }
}

#pragma mark - View controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFinishLoadingFriendList)
                                                     name:@"loadedFriendList"
                                                   object:nil];
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
    
    // disable button at start
    [Constants disableButton:self.sendSong];
    
    // add back button
    UIButton *backButton = [Constants createBackButtonWithText:@"Message"];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:backButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // if no link, initialize new link
    if (!self.myLink)
    {
        self.myLink = [[Link alloc] init];

        // friends arrays
        self.myFriends = [[NSMutableArray alloc] init];
        self.selectedFriends = [[NSMutableArray alloc] init];
        
        // initialize friends list
        for (int i = 0; i < [self.sharedData.myFriends count]; i++)
        {
            self.myFriends[i] = self.sharedData.myFriends[i];
            self.selectedFriends[i] = @NO;
        }
        
        // status boolean
        self.allFriendsSelected = NO;
        
        // create array of buttons
        self.buttons = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < [self.myFriends count] + SPECIAL_CASES; i++)
        {
            UIButton *checkbox = [self createCheckbox];
            checkbox.tag = i;
            
            self.buttons[i] = checkbox;
        }
        
        // reload table
        [self.tableView reloadData];
    }
    
    // if forwarding, change header color
    if (self.isForwarding)
        self.header.backgroundColor = PURPLE;
    
    // update Link information
    self.myLink.sender = self.sharedData.me;

    if (!self.sharedData.isSong)
    {
        self.myLink.isSong = NO;
        
        self.myLink.videoId = self.sharedData.youtubeVideoId;
        self.myLink.title = self.sharedData.youtubeVideoTitle;
        self.myLink.art = self.sharedData.youtubeVideoThumbnail;
        self.myLink.videoChannel = self.sharedData.youtubeVideoChannel;
        self.myLink.videoViews = self.sharedData.youtubeVideoViews;
        self.myLink.videoDuration = self.sharedData.youtubeVideoDuration;
    }
    
    else
    {
        self.myLink.isSong = YES;
        
        self.myLink.title = self.sharedData.iTunesTitle;
        self.myLink.artist = self.sharedData.iTunesArtist;
        self.myLink.album = self.sharedData.iTunesAlbum;
        self.myLink.art = self.sharedData.iTunesArt;
        self.myLink.duration = self.sharedData.iTunesDuration;
        self.myLink.storeURL = self.sharedData.iTunesURL;
        self.myLink.previewURL = self.sharedData.iTunesPreviewURL;
    }
    
    self.myLink.annotation = self.sharedData.annotation;
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
    
    // unsubscribe from notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadedFriendList" object:nil];
}

#pragma mark - UI action methods

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendSongPressed:(id)sender
{
    // check if user has selected any recipients
    BOOL hasSelectedRecipients = NO;
    for (int i = 0; i < [self.selectedFriends count]; i++)
    {
        if ([self.selectedFriends[i] boolValue] == YES)
        {
            hasSelectedRecipients = YES;
        }
    }
    
    if (!hasSelectedRecipients)
        return;
    
    // post link to parse
    PFUser *me = self.sharedData.me;
    [self.myLink saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error)
        {
            // date of post
            NSDate *now = [NSDate date];
            
            // set read/write permissions for current user to YES
            PFACL *ACL = self.myLink.ACL;
            [ACL setReadAccess:YES forUser:me];
            [ACL setWriteAccess:YES forUser:me];
            self.myLink.ACL = ACL;
            
            // set seen status for sender
            // updated by receivers, used by sender inbox
            self.myLink.lastReceiverUpdate = [NSNumber numberWithInt:kLastUpdateNoUpdate];
            self.myLink.lastReceiverUpdateTime = now;
            
            // add recipients
            PFRelation *receivers = [self.myLink relationForKey:@"receivers"];
            self.myLink.receiversData = [[NSMutableArray alloc] init];
            
            for (int i = 0; i < [self.selectedFriends count]; i++)
            {
                if ([self.selectedFriends[i] boolValue] == YES)
                {
                    PFUser *myFriend = self.myFriends[i];
                    [receivers addObject:myFriend];
                    
                    // update read/write permissions
                    PFACL *ACL = self.myLink.ACL;
                    [ACL setReadAccess:YES forUser:self.myFriends[i]];
                    [ACL setWriteAccess:YES forUser:self.myFriends[i]];
                    self.myLink.ACL = ACL;
                    
                    // receiversData for friend i
                    NSMutableDictionary *friendData = [[NSMutableDictionary alloc] init];
                    
                    NSString *myId = me.objectId;
                    NSString *myName = [Constants nameElseUsername:me];
                    
                    // identity/name
                    friendData[@"identity"] = myFriend.objectId;
                    friendData[@"name"] = [Constants nameElseUsername:myFriend];
                    
                    // updated by sender, used by receiver inbox
                    friendData[@"lastSenderUpdate"] = [NSNumber numberWithInt:kLastUpdateNewLink];
                    friendData[@"lastSenderUpdateTime"] = now;
                    
                    // updated by receiver, used by sender message table
                    friendData[@"seen"] = [NSNumber numberWithBool:NO];
                    friendData[@"responded"] = [NSNumber numberWithBool:NO];
                    
                    // updated by receiver, used by both sender/receiver
                    friendData[@"liked"] = [NSNumber numberWithBool:NO];
                    friendData[@"loved"] = [NSNumber numberWithBool:NO];
                    
                    NSMutableDictionary *firstMessage = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:myId, myName, now, self.sharedData.annotation, nil]
                                                                                             forKeys:[NSArray arrayWithObjects:@"identity", @"name", @"time", @"message", nil]];
                    
                    friendData[@"messages"] = [[NSMutableArray alloc] initWithObjects:firstMessage, nil];

                    [self.myLink.receiversData addObject:friendData];
                }
            }
            
            [self.myLink saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error)
                {
                    // send push notifications to recipients
                    NSMutableArray *channels = [[NSMutableArray alloc] init];
                    for (NSDictionary *receiverData in self.myLink.receiversData)
                    {
                        [channels addObject:[NSString stringWithFormat:@"user_%@", [receiverData objectForKey:@"identity"]]];
                    }
                    
                    NSString *alert = [NSString stringWithFormat:@"New link from %@", [Constants nameElseUsername:self.myLink.sender]];
                    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:alert, @"Increment", @"link", nil]
                                                                                     forKeys:[NSArray arrayWithObjects:@"alert", @"badge", @"type", nil]];
                    
                    PFPush *newLinkPush = [[PFPush alloc] init];
                    [newLinkPush setChannels:channels];
                    [newLinkPush setData:data];
                    [newLinkPush sendPushInBackground];
                    
                    // new song sent
                    self.sharedData.newSong = YES;
                    
                    // clear song data
                    if (!self.myLink.isSong)
                    {
                        self.sharedData.youtubeVideoId = nil;
                        self.sharedData.youtubeVideoTitle = nil;
                        self.sharedData.youtubeVideoThumbnail = nil;
                        self.sharedData.youtubeVideoChannel = nil;
                        self.sharedData.youtubeVideoViews = nil;
                        self.sharedData.youtubeVideoDuration = nil;
                    }
                
                    else
                    {
                        self.sharedData.iTunesTitle = nil;
                        self.sharedData.iTunesArtist = nil;
                        self.sharedData.iTunesAlbum = nil;
                        self.sharedData.iTunesArt = nil;
                        self.sharedData.iTunesDuration = nil;
                        self.sharedData.iTunesURL = nil;
                        self.sharedData.iTunesPreviewURL = nil;
                    }
                    
                    self.sharedData.annotation = nil;
                    self.myLink = nil;
                    
                    // load latest sent link
                    // *HIGH PRIORITY UPDATE*
                    [self.sharedData loadSentLinks: kPriorityHigh];
                }
                
                else
                {
                    // Log details of the failure
                    NSLog(@"Error saving link in Parse %@ %@", error, [error userInfo]);
                    
                    // alert user
                }
            }];
        }
        
        else
        {
            // Log details of the failure
            NSLog(@"Error posting new link to Parse %@ %@", error, [error userInfo]);
            
            // alert user
        }
    }];

    // take user to inbox
    if (self.isForwarding)
    {
        UITabBarController *myTBC = (UITabBarController *)[self.navigationController parentViewController];
        
        UINavigationController *leftNav = myTBC.viewControllers[kTabBarIconInbox];
        
        inboxViewController *ivc = leftNav.viewControllers[0]; // root VC
        ivc.selectedSegment = kInboxSent;
        ivc.sentNewLink = YES;
        
        [leftNav popToRootViewControllerAnimated:NO];
    }
    
    else
    {
        UITabBarController *myTBC = (UITabBarController *)[self.navigationController parentViewController];
        
        UINavigationController *leftNav = myTBC.viewControllers[kTabBarIconInbox];
        [leftNav popToRootViewControllerAnimated:YES];
        
        inboxViewController *ivc = leftNav.viewControllers[0]; // root VC
        ivc.selectedSegment = kInboxSent;
        ivc.sentNewLink = YES;
        
        myTBC.selectedViewController = leftNav;
        [self.navigationController popToRootViewControllerAnimated:YES];
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
    return ([self.myFriends count] + ([self.myFriends count] ? SPECIAL_CASES : 0));
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Friends";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.font = GILL_20;
    }
    
    if (indexPath.row == ALL_FRIENDS)
    {
        cell.textLabel.text = @"All Friends";
    }
    
    else
    {
        PFUser *displayPerson = self.myFriends[indexPath.row - SPECIAL_CASES];
        cell.textLabel.text = [Constants nameElseUsername:displayPerson];
    }
    
    // add checkbox
    [cell.contentView addSubview:self.buttons[indexPath.row]];
    
    // if cell is selected, highlight cell
    if (indexPath.row == ALL_FRIENDS)
    {
        if (self.allFriendsSelected)
        {
            cell.layer.borderColor = [UIColor greenColor].CGColor;
            cell.layer.borderWidth = 2.0f;
        }
        
        else cell.layer.borderColor = [UIColor clearColor].CGColor;

    }
    
    else
    {
        if ([self.selectedFriends[indexPath.row - SPECIAL_CASES] boolValue] == YES)
        {
            cell.layer.borderColor = [UIColor greenColor].CGColor;
            cell.layer.borderWidth = 2.0f;
        }
        
        else cell.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    return cell;
}

#pragma mark - Table view action

- (void)toggleChecked:(id)sender
{
    UIButton *clicked = (UIButton *)sender;
    int index = (int)clicked.tag;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    // if checkbox is not selected
    if (!clicked.selected)
    {
        clicked.selected = YES;
        clicked.backgroundColor = [UIColor greenColor];
        selectedCell.layer.borderColor = [UIColor greenColor].CGColor;
        selectedCell.layer.borderWidth = 2.0f;
        
        if (index >= SPECIAL_CASES)
        {
            self.selectedFriends[index - SPECIAL_CASES] = @YES;
        }
        
        else if (index == ALL_FRIENDS)
        {
            for (int i = 0; i < [self.myFriends count]; i++)
            {
                NSIndexPath *pathForRow = [NSIndexPath indexPathForRow:i + SPECIAL_CASES inSection:0];
                UITableViewCell *cellForRow = [self.tableView cellForRowAtIndexPath:pathForRow];
                
                UIButton *buttonForRow = self.buttons[i + SPECIAL_CASES];
                buttonForRow.selected = YES;
                buttonForRow.backgroundColor = [UIColor greenColor];
                
                self.allFriendsSelected = YES;
                
                if (cellForRow) // if cell is currently visible, change state (otherwise don't bother right now)
                {
                    cellForRow.layer.borderColor = [UIColor greenColor].CGColor;
                    cellForRow.layer.borderWidth = 2.0f;
                }
                
                self.selectedFriends[i] = @YES;
            }
        }
        
        // enable button
        [Constants enableButton:self.sendSong];
    }
    
    // if checkbox *is* selected
    else
    {
        clicked.selected = NO;
        clicked.backgroundColor = [UIColor whiteColor];
        selectedCell.layer.borderColor = [UIColor clearColor].CGColor;
        
        if (index >= SPECIAL_CASES)
        {
            self.selectedFriends[index - SPECIAL_CASES] = @NO;
            
            // if "All Friends" is selected, deselect it...
            NSIndexPath *allFriendsPath = [NSIndexPath indexPathForRow:ALL_FRIENDS inSection:0];
            UITableViewCell *allFriends = [self.tableView cellForRowAtIndexPath:allFriendsPath];
            
            UIButton *allFriendsButton = self.buttons[ALL_FRIENDS];
            allFriendsButton.selected = NO;
            allFriendsButton.backgroundColor = [UIColor whiteColor];
            
            self.allFriendsSelected = NO;
            
            if (allFriends) // if cell is currently visible, change state (otherwise don't bother right now)
                allFriends.layer.borderColor = [UIColor clearColor].CGColor;
        }
        
        else if (index == ALL_FRIENDS)
        {
            self.allFriendsSelected = NO;
            
            for (int i = 0; i < [self.myFriends count]; i++)
            {
                NSIndexPath *pathForRow = [NSIndexPath indexPathForRow:i + SPECIAL_CASES inSection:0];
                UITableViewCell *cellForRow = [self.tableView cellForRowAtIndexPath:pathForRow];
                
                UIButton *buttonForRow = self.buttons[i + SPECIAL_CASES];
                buttonForRow.selected = NO;
                buttonForRow.backgroundColor = [UIColor whiteColor];
                
                if (cellForRow) // if cell is currently visible, change state (otherwise don't bother right now)
                    cellForRow.layer.borderColor = [UIColor clearColor].CGColor;
                
                self.selectedFriends[i] = @NO;
            }
        }
        
        
        // check if user has selected *any* recipients
        BOOL hasSelectedRecipients = NO;
        for (int i = 0; i < [self.selectedFriends count]; i++)
        {
            if ([self.selectedFriends[i] boolValue] == YES)
            {
                hasSelectedRecipients = YES;
            }
        }
        
        if (!hasSelectedRecipients)
        {
            // disable button
            [Constants disableButton:self.sendSong];
        }
    }
}

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 5.0f, tableView.frame.size.width, 20.0f)];
    [label setFont:[UIFont boldSystemFontOfSize:16]];
    [label setText:@"Select Recipients"];
    
    [view addSubview:label];
    [view setBackgroundColor:SECTION_HEADER_GRAY];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CONTACTS_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return FRIENDS_HEADER_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    UIButton *pressed = self.buttons[indexPath.row];
    
    if (!pressed.selected)
    {
        selectedCell.layer.borderColor = [UIColor greenColor].CGColor;
        selectedCell.layer.borderWidth = 2.0f;
    }
    
    else selectedCell.layer.borderColor = [UIColor clearColor].CGColor;
    
    [self toggleChecked:self.buttons[indexPath.row]];
}

#pragma mark - UI helper methods

- (UIButton *)createCheckbox
{
    UIButton *checkbox = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [checkbox setFrame:CGRectMake(270.0f, 18.0f, CHECKBOX_SIZE, CHECKBOX_SIZE)];
    
    checkbox.layer.borderColor = [UIColor lightGrayColor].CGColor;
    checkbox.layer.borderWidth = 2.0f;
    
    [checkbox setImage:nil forState:UIControlStateSelected];
    [checkbox setImage:[UIImage imageNamed:@"iconTick"] forState:UIControlStateSelected];
    
    [checkbox addTarget:self action:@selector(toggleChecked:) forControlEvents:UIControlEventTouchUpInside];
    
    return checkbox;
}

@end
