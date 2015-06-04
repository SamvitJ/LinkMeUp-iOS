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



@interface contactsViewController ()

// PRIVATE PROPERTIES **********************************************

@property (nonatomic, strong) NSMutableArray *tableContent;
/* ****************************************
Internal structure of tableContent
 (see -populateTableContent)
 
tableContent: [ [sectionTitle, sectionContent], [sectionTitle, sectionContent], ... ]
(NSMutableArray *)
 
    sectionTitle
    (NSString *)
 
    sectionContent: [ userAndState, userAndState, ...]
    (NSMutableArray *)
 
        userAndState: { "user": (PFUser *)user, "selected": (NSNumber)selected, @"isUser": (NSNumber)isUser }
        (NSMutableDictionary *)

Alternatively...
 tableContent[indexPath.section][0] -> (NSString *)sectionTitle
 tableContent[indexPath.section][1][indexPath.row][@"user"] -> (PFUser *)user
 tableContent[indexPath.section][1][indexPath.row][@"selected"] -> (NSNumber)selected
 tableContent[indexPath.section][1][indexPath.row][@"isUser"] -> (NSNumber)isUser
 
Example
 ["A", [{"user": Aaron, "selected": no, "isUser": yes}, ...] ]
 ["B", [{"user": Becky, "selected": no, "isUser": no}, {"user": Bob, "selected": yes, "isUser": yes}, ...] ]
 ["C", [] ]
 ...
 ["Z", [{"user":Zayn, "selected": yes, "isUser": yes}, ...] ]

 tableContent[2][0] -> "C"
 tableContent[1][1][2][@"user"] -> Bob
 tableContent[1][1][2][@"selected"] -> @YES
 tableContent[1][1][2][@"isUser"] -> @YES
 tableContent[25][1] -> [{"user":Zayn, "selected": yes, "isUser": yes}, ...]
**************************************** */

@property (nonatomic, strong) NSString *predicateFormat;

// *****************************************************************

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

- (void)didFinishLoadingConnections
{
    if (![self.tableContent count]) // empty or nil array
    {
        [self populateTableContent];
        [self.tableView reloadData];
    }
}

#pragma mark - View controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFinishLoadingConnections)
                                                     name:@"loadedConnections"
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
    
    // enable button at start
    [Constants enableButton:self.sendSong];
    
    // add back button
    UIButton *backButton = [Constants createBackButtonWithText:@"Message"];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:backButton];
    
    // set predicate format string
    self.predicateFormat = @"((name != nil) AND (name beginswith[c] %@)) OR ((name = nil) AND (username beginswith[c] %@))";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // if no link, initialize new link and populate table
    if (!self.myLink)
    {
        self.myLink = [[Link alloc] init];

        [self populateTableContent];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadedConnections" object:nil];
}

#pragma mark - Local data/UI state methods

- (void)populateTableContent
{
    // initialize table content
    self.tableContent = [[NSMutableArray alloc] init];
    
    // Single (merged) contacts array
    // NSArray *allContacts = [self.sharedData.myFriends arrayByAddingObjectsFromArray: self.sharedData.nonUserContacts];
    
    for (char c = 'A'; c <= 'Z'; c++)
    {
        NSString *sectionTitle = [NSString stringWithFormat:@"%c", c];
        NSMutableArray *sectionContent = [[NSMutableArray alloc] init];
        
        NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        NSSortDescriptor *sortByUsername = [NSSortDescriptor sortDescriptorWithKey:@"username" ascending:YES];
        
        NSArray *filteredFriends = [self.sharedData.myFriends filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:self.predicateFormat, sectionTitle, sectionTitle]];
        NSArray *sortedFriends = [filteredFriends sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sortByName, sortByUsername, nil]];
        
        NSArray *filteredNonUsers = [self.sharedData.nonUserContacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:self.predicateFormat, sectionTitle, sectionTitle]];
        NSArray *sortedNonUsers = [filteredNonUsers sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortByName]];
        
        for (NSDictionary *friend in sortedFriends)
            [sectionContent addObject:[@{@"user":friend, @"selected": @NO, @"isUser": @YES} mutableCopy]];
        
        for (NSDictionary *nonUser in sortedNonUsers)
            [sectionContent addObject:[@{@"user":nonUser, @"selected": @NO, @"isUser": @NO} mutableCopy]];
        
        /* Single (merged) contacts array
         
        NSArray *filteredContacts = [allContacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:self.predicateFormat, sectionTitle, sectionTitle]];
    
        NSArray *sortedContacts = [filteredContacts sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortByName]];

        for (NSDictionary *contact in sortedContacts)
        {
            BOOL isLmuUser = NO;
            
            if (contact[@"nonUserContact"] == nil)
                isLmuUser = YES;
            
            [sectionContent addObject:[@{@"user":contact, @"selected": @NO, @"isLmuUser": [NSNumber numberWithBool:isLmuUser]} mutableCopy]];
        }*/
        
        [self.tableContent addObject:@[sectionTitle, sectionContent]];
    }
}

- (BOOL)anyContactsSelected:(bool (*)(NSDictionary *userAndState))condition
{
    for (NSArray *sectionData in self.tableContent)
    {
        for (NSDictionary *userAndState in sectionData[1])
        {
            if (([userAndState[@"selected"] boolValue] == YES) && condition(userAndState))
            {
                return YES;
            }
        }
    }
    
    return NO;
}

static bool noCondition(NSDictionary *userAndState)
{
    return true;
}

static bool isUser(NSDictionary *userAndState)
{
    return ([userAndState[@"isUser"] boolValue] == YES);
}

static bool isNonUser(NSDictionary *userAndState)
{
    return ([userAndState[@"isUser"] boolValue] == NO);
}

#pragma mark - MFMessageComposeViewControllerDelegate delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    switch (result)
    {
        case MessageComposeResultCancelled:
        {
            NSLog(@"Cancelled");
            
            // mark as unselected and deselect cell
            self.nonUserSelected[@"selected"] = @NO;
            self.nonUserSelected = nil;
            [self.tableView reloadData];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
            break;
        }
        case MessageComposeResultFailed:
        {
            NSLog(@"Failed to send");
            
            [[[UIAlertView alloc] initWithTitle:@"Unknown Error"
                                        message:@"Failed to Send SMS"
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles: nil] show];
            
            // mark as unselected and deselect cell
            self.nonUserSelected[@"selected"] = @NO;
            self.nonUserSelected = nil;
            [self.tableView reloadData];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
            break;
        }
            
        case MessageComposeResultSent:
        {
            NSLog(@"Message sent");
            
            [self dismissViewControllerAnimated:NO completion: ^{
                [self postLinkAndSendPush];
            }];
            
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - UI action methods

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)toggleChecked:(id)sender
{
    UIButton *clicked = (UIButton *)sender;
    long index = (long)clicked.tag;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self rowForEncodedTag:index] inSection:[self sectionForEncodedTag:index]];
    
    [self toggleStateForIndexPath:indexPath];
}

- (void)toggleStateForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIButton *checkbox = (UIButton *)[cell viewWithTag:[self encodeIndexPath:indexPath]];
    
    NSMutableDictionary *userAndState = self.tableContent[indexPath.section][1][indexPath.row];
    
    if ([userAndState[@"selected"] boolValue] == NO)
    {
        // select checkbox
        checkbox.selected = YES;
        checkbox.backgroundColor = [UIColor greenColor];
        
        // outline cell
        cell.layer.borderColor = [UIColor greenColor].CGColor;
        cell.layer.borderWidth = 2.0f;
        
        // cases
        if ([userAndState[@"isUser"] boolValue] == NO)
        {
            // present text message UI
            self.nonUserSelected = userAndState;
            [self showMessageComposeInterfaceForUser:userAndState[@"user"]];
        }
        else if ([userAndState[@"isUser"] boolValue] == YES && ![self anyContactsSelected: &noCondition])
        {
            // show "Send Link!" button and disable non users
            [self animateSendButtonInDirection:kDirectionUp];
            
            self.nonUsersDisabled = YES;
            [self.tableView reloadData];
        }
        else if ([userAndState[@"isUser"] boolValue] == YES && [self anyContactsSelected: &isUser])
        {
            // do nothing
        }
        
        // update state
        userAndState[@"selected"] = @YES;
    }
    
    else // ([userAndState[@"selected"] boolValue] == YES)
    {
        // update state
        userAndState[@"selected"] = @NO;
        
        // deselect checkbox
        checkbox.selected = NO;
        checkbox.backgroundColor = [UIColor whiteColor];
        
        // unoutline cell
        cell.layer.borderColor = [UIColor clearColor].CGColor;
        
        // cases
        if (![self anyContactsSelected: &noCondition])
        {
            // hide "Send Link!" button and enable sending to non-users
            [self animateSendButtonInDirection:kDirectionDown];
            
            self.nonUsersDisabled = NO;
            [self.tableView reloadData];
        }
        else
        {
            // do nothing
        }
    }
}

- (void)showMessageComposeInterfaceForUser:(NSDictionary *)user
{
    // send text message
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    if([MFMessageComposeViewController canSendText])
    {
        NSMutableString *message = [[NSMutableString alloc] init];
        
        NSString *link;
        if ([self.myLink.annotation isEqualToString:@""])
        {
            if (!self.myLink.isSong)
            {
                link = [NSString stringWithFormat:@"Check out %@ at www.youtube.com/watch?v=%@.", self.myLink.title, self.myLink.videoId];
            }
            else
            {
                link = [NSString stringWithFormat:@"Check out %@ by %@.", self.myLink.title, self.myLink.artist];
            }
            
            [message appendString:link];
        }
        else
        {
            if (!self.myLink.isSong)
            {
                link = [NSString stringWithFormat:@"www.youtube.com/watch?v=%@.", self.myLink.videoId];
            }
            else
            {
                link = [NSString stringWithFormat:@"%@ | %@.", self.myLink.title, self.myLink.artist];
            }
            
            [message appendString:link];
            [message appendString:@"\n\n"];
            [message appendString:self.myLink.annotation];
        }
    
        [message appendString:@"\n\n"];
        [message appendString:@"Sent via LinkMeUp."];
        // NSString *htmlLink = @"<a href=\"https://itunes.apple.com/us/app/linkmeup!/id916400771?mt=8\"> LinkMeUp.</a>";
        // NSString *availableAt = @"available at https://itunes.apple.com/us/app/linkmeup!/id916400771?mt=8";
        
        controller.body = message;
        
        controller.recipients = [NSArray arrayWithObjects:[user[@"phone"] firstObject], nil];
        controller.messageComposeDelegate = self;
        
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (IBAction)sendSongPressed:(id)sender
{
    // check if user has selected any recipients
    if (![self anyContactsSelected: &noCondition])
        return;
    
    [self postLinkAndSendPush];
}

- (void)postLinkAndSendPush
{
    // post link to parse
    PFUser *me = self.sharedData.me;
    [self.myLink saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error)
        {
            // date of post
            NSDate *now = [NSDate date];
            
            // sent to LMU users or as text
            if (self.nonUserSelected)
                self.myLink.isText = YES;
            
            else self.myLink.isText = NO;
            
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
            
            for (NSArray *sectionData in self.tableContent)
            {
                for (NSDictionary *userAndState in sectionData[1])
                {
                    if ([userAndState[@"selected"] boolValue] == YES)
                    {
                        if ([userAndState[@"isUser"] boolValue] == YES)
                        {
                            PFUser *myFriend = userAndState[@"user"];
                            [receivers addObject:myFriend];
                            
                            // update read/write permissions
                            PFACL *ACL = self.myLink.ACL;
                            [ACL setReadAccess:YES forUser:myFriend];
                            [ACL setWriteAccess:YES forUser:myFriend];
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
                        else
                        {
                            // receiversData for mobile contact
                            NSMutableDictionary *friendData = [[NSMutableDictionary alloc] init];
                            
                            NSString *myId = me.objectId;
                            NSString *myName = [Constants nameElseUsername:me];
                            
                            // name and identity
                            friendData[@"identity"] = @"mobile contact";
                            friendData[@"name"] = [NSString stringWithFormat:@"Text sent to %@", userAndState[@"user"][@"name"]];
                            
                            NSMutableDictionary *firstMessage = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:myId, myName, now, self.sharedData.annotation, nil]
                                                                                                     forKeys:[NSArray arrayWithObjects:@"identity", @"name", @"time", @"message", nil]];
                            
                            friendData[@"messages"] = [[NSMutableArray alloc] initWithObjects:firstMessage, nil];
                            
                            [self.myLink.receiversData addObject:friendData];
                        }
                    }
                }
            }
            
            [self.myLink saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error)
                {
                    // if sent to LMU users
                    if (!self.nonUserSelected)
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
                    }
                    
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
    
    [self transitionToNextVC];
}

- (void)transitionToNextVC
{
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

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *sectionTitles = [[NSMutableArray alloc] init];
    
    for (NSArray *sectionData in self.tableContent)
        [sectionTitles addObject: sectionData[0]];
    
    return [sectionTitles copy];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableContent count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableContent[section][1] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Friends";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
   
    // cell appearance
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.font = GILL_20;
    
    // cell data
    NSMutableDictionary *userAndState = self.tableContent[indexPath.section][1][indexPath.row];
    
    // cell text label
    cell.textLabel.text = [Constants nameElseUsername:(PFUser *)userAndState[@"user"]];

    // if LMU user, add icon to cell
    if ([userAndState[@"isUser"] boolValue] == YES)
    {
        cell.detailTextLabel.text = @"LinkMeUp";
        //cell.imageView.image = [UIImage imageNamed:@"icon_app_58.png"];
    }
    
    // add checkbox
    UIButton *checkbox = [self createCheckbox];
    checkbox.tag = [self encodeIndexPath:indexPath];
    
    [cell addSubview:checkbox];
    
    // set cell state
    if (self.nonUsersDisabled && ([userAndState[@"isUser"] boolValue] == NO))
    {
        cell.contentView.alpha = ALPHA_DISABLED;
        cell.userInteractionEnabled = NO;
        
        checkbox.alpha = ALPHA_DISABLED;
        checkbox.userInteractionEnabled = NO;
    }
    else
    {
        cell.contentView.alpha = 1;
        cell.userInteractionEnabled = YES;
        
        checkbox.alpha = 1;
        checkbox.userInteractionEnabled = YES;
    }
    
    if ([userAndState[@"selected"] boolValue] == YES)
    {
        cell.layer.borderColor = [UIColor greenColor].CGColor;
        cell.layer.borderWidth = 2.0f;
        
        checkbox.selected = YES;
        checkbox.backgroundColor = [UIColor greenColor];
    }
    else
    {
        cell.layer.borderColor = [UIColor clearColor].CGColor;
        
        checkbox.selected = NO;
        checkbox.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // if no rows in section, return nil
    if ([self tableView:tableView numberOfRowsInSection:section] == 0)
        return nil;
    
    UIView *view = [[UIView alloc] init];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 5.0f, tableView.frame.size.width, 20.0f)];
    [label setFont:[UIFont boldSystemFontOfSize:16]];
    [label setText:self.tableContent[section][0]];
    
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
    // if no rows in section, return 0
    if ([self tableView:tableView numberOfRowsInSection:section] == 0)
        return 0;
    
    return FRIENDS_HEADER_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self toggleStateForIndexPath:indexPath];
}

#pragma mark - UI helper methods

- (long)encodeIndexPath:(NSIndexPath *)indexPath
{
    // encode section and row in ONE integer for UIButton tag
    return ((indexPath.section + 1) * 1000) + indexPath.row;
}

- (long)sectionForEncodedTag:(long)tag
{
    return (tag / 1000) - 1;
}

- (long)rowForEncodedTag:(long)tag
{
    return (tag % 1000);
}

- (UIButton *)createCheckbox
{
    UIButton *checkbox = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [checkbox setFrame:CGRectMake(265.0f, 18.0f, CHECKBOX_SIZE, CHECKBOX_SIZE)];
    
    checkbox.layer.borderColor = [UIColor lightGrayColor].CGColor;
    checkbox.layer.borderWidth = 2.0f;

    [checkbox setImage:[UIImage imageNamed:@"iconTick"] forState:UIControlStateSelected];
    
    [checkbox addTarget:self action:@selector(toggleChecked:) forControlEvents:UIControlEventTouchUpInside];
    
    return checkbox;
}

#pragma mark - UIButton animation

- (void)animateSendButtonInDirection:(Direction)direction
{
    float distance = 50.0f;
    float movement = (direction ? distance : -distance);
    float movementDuration = 0.2f;
    
    [UIView beginAnimations:@"Scroll" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    
    self.sendSong.frame = CGRectOffset(self.sendSong.frame, 0.0f, movement);
    
    [UIView commitAnimations];
}

@end
