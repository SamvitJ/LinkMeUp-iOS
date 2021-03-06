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
#import "contactsTableViewCell.h"

#import "findContactsViewController.h"

#import "inboxViewController.h"


// used by Send Link button textLabel//scrollView
static const CGFloat kSendLinkLabelLeftOffset = 15.0;
static const CGFloat kSendLinkLabelRightOffset = 45.0;

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
 
    sectionContent: [ contactAndState, contactAndState, ...]
    (NSMutableArray *)
 
        contactAndState: { "contact": (PFUser *)contact, "selected": (NSNumber)selected, @"isUser": (NSNumber)isUser }
        (NSMutableDictionary *)

Alternatively...
 tableContent[indexPath.section][0] -> (NSString *)sectionTitle
 tableContent[indexPath.section][1][indexPath.row][@"contact"] -> (PFUser *)contact
 tableContent[indexPath.section][1][indexPath.row][@"selected"] -> (NSNumber)selected
 tableContent[indexPath.section][1][indexPath.row][@"isUser"] -> (NSNumber)isUser
 
Example
 ["A", [{"contact": Aaron, "selected": no, "isUser": yes}, ...] ]
 ["B", [{"contact": Becky, "selected": no, "isUser": no}, {"contact": Bob, "selected": yes, "isUser": yes}, ...] ]
 ["C", [] ]
 ...
 ["Z", [{"contact":Zayn, "selected": yes, "isUser": yes}, ...] ]

 tableContent[2][0] -> "C"
 tableContent[1][1][2][@"contact"] -> Bob
 tableContent[1][1][2][@"selected"] -> @YES
 tableContent[1][1][2][@"isUser"] -> @YES
 tableContent[25][1] -> [{"contact": Zayn, "selected": yes, "isUser": yes}, ...]
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
    if (![self haveContacts]) // empty or nil array
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
                                                     name:kLoadedConnections
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
    
    // initialize variables
    self.selectedRecipients = [[NSMutableArray alloc] init];
    
    // add recipient list text view
    [self createSendButtonLabel];
    
    // set label state based on button state
    [self.sendSong addTarget:self action:@selector(sendSongStateChanged:) forControlEvents:(UIControlStateNormal | UIControlStateHighlighted | UIControlStateSelected)];
    [self.sendSong addTarget:self action:@selector(sendSongDragExit:) forControlEvents:UIControlEventTouchDragExit];
    [self.sendSong addTarget:self action:@selector(sendSongDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
    
    // display findContactsViewController, if appropriate
    if (self.sharedData.loadedAllConnections)
    {
        [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(presentFindContacts) userInfo:nil repeats:NO];
    }
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLoadedConnections object:nil];
}

#pragma mark - Address book permissions

- (void)presentFindContacts
{
    bool requestsRemaining = ([self.sharedData.me[kNumberABRequests] integerValue] < AB_REQUESTS_LIMIT);
    bool haveContacts = [self haveContacts];
    
    NSLog(@"AB conditions contactsVC - %u %u %u", self.sharedData.hasAddressBookAccess, requestsRemaining, haveContacts);
    
    if (!self.sharedData.hasAddressBookAccess && requestsRemaining && !haveContacts)
    {
        findContactsViewController *cwfvc = [[findContactsViewController alloc] init];
        [self presentViewController:cwfvc animated:YES completion:nil];
    }
}

#pragma mark - Local data/state methods

- (BOOL)haveContacts
{
    return ([self.sharedData.myFriends count] > 0) || ([self.sharedData.suggestedFriends count] > 0) ||
    ([self.sharedData.requestSenders count] > 0) | ([self.sharedData.nonUserContacts count] > 0);
}

- (void)populateTableContent
{
    // initialize table content
    self.tableContent = [[NSMutableArray alloc] init];
    
    // friends + suggestions + request senders
    NSArray *allUsers = [[[self.sharedData.myFriends arrayByAddingObjectsFromArray:self.sharedData.suggestedFriends] arrayByAddingObjectsFromArray: self.sharedData.requestSenders] arrayByAddingObject:self.sharedData.me];
    bool manyLMUContacts = ([allUsers count] >= MANY_LMU_CONTACTS ? true : false);
    
    // alphabetical section
    for (char c = 'A'; c <= 'Z'; c++)
    {
        NSString *sectionTitle = [NSString stringWithFormat:@"%c", c];
        NSMutableArray *sectionContent = [[NSMutableArray alloc] init];
        
        // sort descriptors
        NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        NSSortDescriptor *sortByUsername = [NSSortDescriptor sortDescriptorWithKey:@"username" ascending:YES];
        
        // if many LMU contacts, include with all others in alphabetical sections
        if (manyLMUContacts)
        {
            NSArray *filteredUsers = [allUsers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:self.predicateFormat, sectionTitle, sectionTitle]];
            
            // this isn't exactly what we want, but it works for now
            NSArray *sortedUsers = [filteredUsers sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sortByName, sortByUsername, nil]];
        
            for (NSDictionary *user in sortedUsers)
                [sectionContent addObject:[@{@"contact":user, @"selected": @NO, @"isUser": @YES} mutableCopy]];
        }
            
        NSArray *filteredNonUsers = [self.sharedData.nonUserContacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:self.predicateFormat, sectionTitle, sectionTitle]];
        NSArray *sortedNonUsers = [filteredNonUsers sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortByName]];

        for (NSDictionary *nonUser in sortedNonUsers)
            [sectionContent addObject:[@{@"contact":nonUser, @"selected": @NO, @"isUser": @NO} mutableCopy]];
        
        [self.tableContent addObject:@[sectionTitle, sectionContent]];
    }
    
    // if not many LMU contacts, add LMU-only section near top
    if (!manyLMUContacts)
    {
        NSString *usersIndexTitle = UNICODE_LINK;
        NSMutableArray *usersContent = [[NSMutableArray alloc] init];
        
        NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
        NSArray *sortedUsers = [allUsers sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sortByDate, nil]];
        
        // add all users that are not also recentRecipients
        for (PFUser *user in sortedUsers)
        {
            bool isInRecents = false;
            
            for (NSDictionary *recent in self.sharedData.recentRecipients)
            {
                if ([recent[@"isUser"] boolValue] == YES)
                {
                    PFUser *recentUser = (PFUser *)recent[@"contact"];
                    
                    if ([recentUser.objectId isEqualToString:user.objectId])
                    {
                        isInRecents = true;
                        break;
                    }
                }
            }
            
            if (!isInRecents)
            {
                [usersContent addObject:[@{@"contact":user, @"selected": @NO, @"isUser": @YES} mutableCopy]];
            }
        }
     
        // add to top
        [self.tableContent insertObject:@[usersIndexTitle, usersContent] atIndex:0];
    }
    
    // recents section
    NSString *recentsIndexTitle = UNICODE_WATCH;
    NSMutableArray *recentsContent = [[NSMutableArray alloc] init];
    
    // show most recent first
    NSEnumerator *reversedRecents = [self.sharedData.recentRecipients reverseObjectEnumerator];
    
    // populate recents section of tableContent
    for (NSDictionary *recent in reversedRecents)
    {
        // if LMU user...
        if ([recent[@"isUser"] boolValue] == YES)
        {
            PFUser *userPointer = recent[@"contact"];
            
            // if not already in table, must create new contactAndState dictionary
            if (!manyLMUContacts)
            {
                // find full user info
                for (PFUser *user in allUsers)
                {
                    if ([user.objectId isEqualToString:userPointer.objectId])
                    {
                        [recentsContent addObject:[@{@"contact":user, @"selected": @NO, @"isUser": @YES} mutableCopy]];
                    }
                }
            }
            // else user has already been added to table, so find (and point to) existing contactAndState
            else
            {
                // traverse through table content to find same PFUser
                for (NSArray *section in self.tableContent)
                {
                    for (NSDictionary *userAndState in section[1])
                    {
                        if ([userAndState[@"isUser"] boolValue] == YES)
                        {
                            PFUser *user = userAndState[@"contact"];
                            
                            // found same PFUser
                            if ([userPointer.objectId isEqualToString:user.objectId])
                            {
                                [recentsContent addObject:userAndState];
                            }
                        }
                    }
                }
            }
        }
        else
        {
            NSDictionary *nonUserPointer = recent[@"contact"];
            
            // traverse through table content to find same non-user
            for (NSArray *section in self.tableContent)
            {
                for (NSDictionary *userAndState in section[1])
                {
                    if ([userAndState[@"isUser"] boolValue] == NO)
                    {
                        NSDictionary *nonUser = userAndState[@"contact"];
                        
                        // found same non-user
                        if ([nonUserPointer isEqual:nonUser])
                        {
                            [recentsContent addObject:userAndState];
                        }
                    }
                }
            }
        }
    }
    
    [self.tableContent insertObject:@[recentsIndexTitle, recentsContent] atIndex:0];
}

- (void)updateRecipientListWithContact:(NSDictionary *)contactAndState action:(RecipientList)action
{
    // check if already in recipients
    // if LMU user
    if ([contactAndState[@"isUser"] boolValue] == YES)
    {
        for (NSDictionary *selectedRecipient in self.selectedRecipients)
        {
            if ([selectedRecipient[@"isUser"] boolValue] == NO)
                continue;
            
            PFUser *stored = selectedRecipient[@"contact"];
            PFUser *current = contactAndState[@"contact"];
            
            // if match found, update its position
            if ([stored.objectId isEqualToString: current.objectId])
            {
                [self.selectedRecipients removeObject:selectedRecipient];
                break;
            }
        }
    }
    else // if non-user
    {
        for (NSDictionary *selectedRecipient in self.selectedRecipients)
        {
            if ([selectedRecipient[@"isUser"] boolValue] == YES)
                continue;
            
            NSDictionary *stored = selectedRecipient[@"contact"];
            NSDictionary *current = selectedRecipient[@"contact"];
            
            // if match found, update its position
            if ([stored isEqual: current])
            {
                [self.selectedRecipients removeObject:selectedRecipient];
                break;
            }
        }
    }
    
    if (action == kListAdd)
        [self.selectedRecipients addObject:contactAndState];
}

- (void)updateSendButtonText
{
    NSMutableArray *namesArray = [[NSMutableArray alloc] init];
    
    for (NSDictionary *contactAndState in self.selectedRecipients)
    {
        NSString *firstName = contactAndState[@"contact"][@"first_name"];
        
        if (!firstName)
            firstName = [[contactAndState[@"contact"][@"name"] componentsSeparatedByString:@" "] firstObject];
        
        if (!firstName)
            firstName = contactAndState[@"contact"][@"username"];
        
        // if user is me, use "me" instead of my name
        if ([contactAndState[@"isUser"] boolValue] == YES)
        {
            PFUser *user = contactAndState[@"contact"];
            
            if ([user.objectId isEqualToString:self.sharedData.me.objectId])
            {
                firstName = @"me";
            }
        }
        
        [namesArray addObject: firstName];
    }

    NSString *namesString = [Constants stringForArray:namesArray withKey:nil];
    NSLog(@"Names string %@", namesString);
    
    self.textLabel.text = namesString;
    [self updateSendButtonLabel];
}

#pragma mark - MFMessageComposeViewControllerDelegate methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    switch (result)
    {
        case MessageComposeResultCancelled:
        {
            NSLog(@"Cancelled");
            
            // mark as unselected
            NSMutableDictionary *nonUserSelected = [self.selectedRecipients firstObject];
            nonUserSelected[@"selected"] = @NO;
            [self updateRecipientListWithContact:nonUserSelected action:kListRemove];
            
            // deselect cell
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
            
            // mark as unselected
            NSMutableDictionary *nonUserSelected = [self.selectedRecipients firstObject];
            nonUserSelected[@"selected"] = @NO;
            [self updateRecipientListWithContact:nonUserSelected action:kListRemove];
            
            // deselect cell
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

#pragma mark - UIButton target methods

- (void)sendSongDragEnter:(id)sender
{
    // NSLog(@"Dragged enter");
    
    [UIView beginAnimations:@"fade out" context:NULL];
    [UIView setAnimationDuration: 0.4];
    self.textLabel.alpha = 0.3;
    [UIView commitAnimations];
}

- (void)sendSongDragExit:(id)sender
{
    // NSLog(@"Dragged exit");
    
    [UIView beginAnimations:@"fade in" context:NULL];
    [UIView setAnimationDuration: 0.4];
    self.textLabel.alpha = 1.0;
    [UIView commitAnimations];
}

- (void)sendSongStateChanged:(id)sender
{
    if (self.sendSong.state == UIControlStateHighlighted || self.sendSong.state == UIControlStateSelected)
        self.textLabel.alpha = 0.3;
    
    else self.textLabel.alpha = 1.0;
}

#pragma mark - Gesture recognizer selectors

/*- (void)handlePress:(UILongPressGestureRecognizer *)sender
{
    NSLog(@"Handle press");
    
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        NSLog(@"Long press began");
        [self sendSongDragEnter: nil];
    }
    else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateFailed)
    {
        NSLog(@"Long press ended, cancelled, or failed");
        [self sendSongDragExit: nil];
    }
}*/

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"Ended");
        
        [self sendSongPressed:nil];
    }
    else if (sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateFailed)
    {
        NSLog(@"Cancelled/failed");
        return;
    }
    else
    {
        NSLog(@"Other");
        return;
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
    
    NSMutableDictionary *contactAndState = self.tableContent[indexPath.section][1][indexPath.row];
    
    if ([contactAndState[@"selected"] boolValue] == NO)
    {
        // update state
        contactAndState[@"selected"] = @YES;
        [self updateRecipientListWithContact:(NSDictionary *)contactAndState action:kListAdd];
        
        // select checkbox
        checkbox.selected = YES;
        checkbox.backgroundColor = [UIColor greenColor];
        
        // outline cell
        cell.layer.borderColor = [UIColor greenColor].CGColor;
        cell.layer.borderWidth = 2.0f;
        
        // cases
        if ([contactAndState[@"isUser"] boolValue] == NO)
        {
            // present text message UI
            [self showMessageComposeInterfaceForContact:contactAndState[@"contact"]];
        }
        else if ([contactAndState[@"isUser"] boolValue] == YES && ([self.selectedRecipients count] == 1))
        {
            // show "Send Link!" button
            [self animateSendButtonInDirection:kDirectionUp];
            
            // disable non users
            self.nonUsersDisabled = YES;
            [self.tableView reloadData];
        }
        else if ([contactAndState[@"isUser"] boolValue] == YES && ([self.selectedRecipients count] > 1))
        {
            // do nothing
        }
    }
    
    else // ([contactAndState[@"selected"] boolValue] == YES)
    {
        // update state
        contactAndState[@"selected"] = @NO;
        [self updateRecipientListWithContact:(NSDictionary *)contactAndState action:kListRemove];
        
        // deselect checkbox
        checkbox.selected = NO;
        checkbox.backgroundColor = [UIColor whiteColor];
        
        // unoutline cell
        cell.layer.borderColor = [UIColor clearColor].CGColor;
        
        // cases
        if (![self.selectedRecipients count])
        {
            // hide "Send Link!" button
            [self animateSendButtonInDirection:kDirectionDown];
            
            // enable sending to non-users
            self.nonUsersDisabled = NO;
            [self.tableView reloadData];
        }
    }
    
    // reload data to select/deselect duplicate cell on screen
    [self.tableView reloadData];
    
    // update send button
    [self updateSendButtonText];
}

- (void)showMessageComposeInterfaceForContact:(NSDictionary *)contact
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
                link = [NSString stringWithFormat:@"%@ - www.youtube.com/watch?v=%@", self.myLink.title, self.myLink.videoId];
            }
            else
            {
                link = [NSString stringWithFormat:@"Check out %@ by %@.", self.myLink.title, self.myLink.artist];
            }
            
            [message appendString:link];
        }
        else
        {
            [message appendString:self.myLink.annotation];
            [message appendString:@" "];
            
            if (!self.myLink.isSong)
            {
                link = [NSString stringWithFormat:@"www.youtube.com/watch?v=%@", self.myLink.videoId];
            }
            else
            {
                link = [NSString stringWithFormat:@"%@ | %@.", self.myLink.title, self.myLink.artist];
            }
            
            [message appendString:link];
        }
    
        // App Store link
        [message appendString:@"\n\n"];
        [message appendString:@"Sent via LinkMeUp (www.linkmeupmessenger.com)"];
        
        controller.body = message;
        
        controller.recipients = [NSArray arrayWithObjects:[contact[@"phone"] firstObject], nil];
        controller.messageComposeDelegate = self;
        
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (IBAction)sendSongPressed:(id)sender
{
    // check if user has selected any recipients
    if (![self.selectedRecipients count])
        return;
    
    [self postLinkAndSendPush];
}

- (void)postLinkAndSendPush
{
    PFUser *me = self.sharedData.me;
    
    // date of post
    NSDate *now = [NSDate date];
    
    // sent to LMU users or as text
    if (self.nonUsersDisabled)
        self.myLink.isText = NO;
    
    else self.myLink.isText = YES;
    
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
    
    for (NSDictionary *contactAndState in self.selectedRecipients)
    {
        // update recently sent
        
        // initialize if empty
        if (!self.sharedData.recentRecipients)
            self.sharedData.recentRecipients = [[NSMutableArray alloc] init];
        
        // check if already in recents
        if ([contactAndState[@"isUser"] boolValue] == YES)
        {
            for (NSDictionary *recentRecipient in self.sharedData.recentRecipients)
            {
                if ([recentRecipient[@"isUser"] boolValue] == NO)
                    continue;
                
                PFUser *stored = recentRecipient[@"contact"];
                PFUser *current = contactAndState[@"contact"];
                
                // if match found, update its position
                if ([stored.objectId isEqualToString: current.objectId])
                {
                    [self.sharedData.recentRecipients removeObject:recentRecipient];
                    break;
                }
            }
        }
        else
        {
            for (NSDictionary *recentRecipient in self.sharedData.recentRecipients)
            {
                if ([recentRecipient[@"isUser"] boolValue] == YES)
                    continue;
                
                NSDictionary *stored = recentRecipient[@"contact"];
                NSDictionary *current = contactAndState[@"contact"];
                
                // if match found, update its position
                if ([stored isEqual: current])
                {
                    [self.sharedData.recentRecipients removeObject:recentRecipient];
                    break;
                }
            }
        }
        
        // remove least recent if array is full
        if ([self.sharedData.recentRecipients count] >= NUMBER_RECENTS)
            [self.sharedData.recentRecipients removeObjectAtIndex:0];
        
        // add to front
        [self.sharedData.recentRecipients addObject:@{@"contact": contactAndState[@"contact"], @"isUser": contactAndState[@"isUser"]}];
        
        
        
        // update link data
        if ([contactAndState[@"isUser"] boolValue] == YES)
        {
            PFUser *myFriend = contactAndState[@"contact"];
            
            bool isMe = [myFriend.objectId isEqualToString: self.sharedData.me.objectId];
            
            // add friend to receivers field
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
            friendData[@"name"] = (isMe ? @"me" : [Constants nameElseUsername:myFriend]);
            
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
        
        else // text message recipient
        {
            // receiversData for mobile contact
            NSMutableDictionary *friendData = [[NSMutableDictionary alloc] init];
            
            NSString *myId = me.objectId;
            NSString *myName = [Constants nameElseUsername:me];
            
            // name and identity
            friendData[@"identity"] = @"mobile contact";
            friendData[@"name"] = [NSString stringWithFormat:@"Text sent to %@", contactAndState[@"contact"][@"name"]];
            
            NSMutableDictionary *firstMessage = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:myId, myName, now, self.sharedData.annotation, nil]
                                                                                     forKeys:[NSArray arrayWithObjects:@"identity", @"name", @"time", @"message", nil]];
            
            friendData[@"messages"] = [[NSMutableArray alloc] initWithObjects:firstMessage, nil];
            
            [self.myLink.receiversData addObject:friendData];
        }
    }

    // save recents in Parse
    self.sharedData.me[@"recentRecipients"] = self.sharedData.recentRecipients;
    [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error)
        {
            NSLog(@"Error updating recent recipients %@ %@", error, [error userInfo]);
        }
    }];
    
    // save link in Parse and send push
    [self.myLink saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error)
        {
            // if sent to LMU users
            if (self.nonUsersDisabled)
            {
                // send push notifications to recipients
                NSMutableArray *channels = [[NSMutableArray alloc] init];
                for (NSDictionary *receiverData in self.myLink.receiversData)
                {
                    NSString *receiverId = receiverData[@"identity"];
                    
                    // add channel, if not me
                    if (![receiverId isEqualToString: self.sharedData.me.objectId])
                    {
                        [channels addObject:[NSString stringWithFormat:@"user_%@", receiverId]];
                    }
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
    NSLog(@"%@ %lu", title, (long)index);
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
    
    contactsTableViewCell *cell = [[contactsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
   
    // cell appearance
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor whiteColor];
    
    // cell data
    NSMutableDictionary *contactAndState = self.tableContent[indexPath.section][1][indexPath.row];
    
    // cell text label
    cell.contactLabel.text = [Constants nameElseUsername:(PFUser *)contactAndState[@"contact"]];
    
    // special case - if me, add "(me)" to end of name
    if ([contactAndState[@"isUser"] boolValue] == YES)
    {
        PFUser *user = contactAndState[@"contact"];
        
        if ([user.objectId isEqualToString:self.sharedData.me.objectId])
        {
            cell.contactLabel.text = [NSString stringWithFormat:@"%@ (me)", cell.contactLabel.text];
        }
    }

    // add appropriate icon image to cell
    if ([contactAndState[@"isUser"] boolValue] == YES)
    {
        cell.icon.image = [UIImage imageNamed:@"icon_app_58.png"];
    }
    else
    {
        cell.icon.image = [UIImage imageNamed:@"iPhoneMessages.png"];
    }
    
    // add checkbox
    UIButton *checkbox = [self createCheckbox];
    checkbox.tag = [self encodeIndexPath:indexPath];
    
    [cell addSubview:checkbox];
    
    // set cell state - enabled/disabled
    if (self.nonUsersDisabled && ([contactAndState[@"isUser"] boolValue] == NO))
    {
        cell.contentView.alpha = ALPHA_DISABLED;
        cell.contactLabel.alpha = ALPHA_DISABLED;
        cell.icon.alpha = ALPHA_DISABLED;
        cell.userInteractionEnabled = NO;
        
        checkbox.alpha = ALPHA_DISABLED;
        checkbox.userInteractionEnabled = NO;
    }
    else
    {
        cell.contentView.alpha = 1;
        cell.contactLabel.alpha = 1;
        cell.icon.alpha = 1;
        cell.userInteractionEnabled = YES;
        
        checkbox.alpha = 1;
        checkbox.userInteractionEnabled = YES;
    }
    
    // set cell state - selected/unselected
    if ([contactAndState[@"selected"] boolValue] == YES)
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
    
    // set section title (same as index title, except for Recents and LMU Users sections)
    NSString *sectionTitle;
    
    if (section == 0)
    {
        sectionTitle = @"Recents";
    }
    else if (section == 1 && [self.tableContent[section][0] isEqualToString: UNICODE_LINK])
    {
        sectionTitle = @"LinkMeUp Users";
    }
    else
    {
        sectionTitle = self.tableContent[section][0];
    }
    
    [label setText: sectionTitle];
    
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // create footer for last table view section if send button visible
    if (section == ([self.tableContent count] - 1) && self.nonUsersDisabled)
    {
        return self.sendSong.frame.size.height;
    }
    
    else return 0;
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

- (void)createSendButtonLabel
{
    // parameters
    const CGFloat labelLeftOffset = kSendLinkLabelLeftOffset;
    const CGFloat labelRightOffset = kSendLinkLabelRightOffset;
    
    // embedded label
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelLeftOffset, 0, self.sendSong.frame.size.width - (labelLeftOffset + labelRightOffset), self.sendSong.frame.size.height)];
    
    self.textLabel.font = CHALK_18;
    self.textLabel.textColor = [UIColor whiteColor];
    // self.textLabel.highlightedTextColor = [UIColor colorWithHue:0.00 saturation:0.01 brightness:1.00 alpha: 0.3];
    
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    // scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.sendSong.frame.size.width - labelRightOffset, self.sendSong.frame.size.height)];
    
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;

    // add tap gesture recognizer to scroll view
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.cancelsTouchesInView = NO;
    [self.scrollView addGestureRecognizer:tap];

    /*UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
    press.numberOfTapsRequired = 1;
    press.numberOfTouchesRequired = 1;
    press.minimumPressDuration = 1.0;
    [self.scrollView addGestureRecognizer:press];*/
    
    // add to subviews
    [self.scrollView addSubview: self.textLabel];
    [self.sendSong addSubview: self.scrollView];
}

- (void)updateSendButtonLabel
{
    // parameters
    const CGFloat labelLeftOffset = kSendLinkLabelLeftOffset;
    const CGFloat labelRightOffset = kSendLinkLabelRightOffset;
    const CGFloat scrollViewRightBuffer = 10.0;
    
    // size of current label text
    CGSize newSize = [self.textLabel.text sizeWithAttributes: @{NSFontAttributeName: CHALK_18}];
    
    CGFloat scrollViewWidth = MIN(self.sendSong.frame.size.width - labelRightOffset, labelLeftOffset + newSize.width + scrollViewRightBuffer);
    
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, newSize.width, self.textLabel.frame.size.height);
    
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, scrollViewWidth, self.scrollView.frame.size.height);
    self.scrollView.contentSize = CGSizeMake(labelLeftOffset + newSize.width + scrollViewRightBuffer, self.scrollView.contentSize.height);
    
    // NSLog(@"String size %@", NSStringFromCGSize(newSize));
    // NSLog(@"Content size %@", NSStringFromCGSize(self.scrollView.contentSize));
    // NSLog(@"Bounds size %@", NSStringFromCGSize(self.scrollView.bounds.size));
    
    CGFloat newContentOffsetX = MAX(0, self.scrollView.contentSize.width - self.scrollView.bounds.size.width);
    [self.scrollView setContentOffset:CGPointMake(newContentOffsetX, self.scrollView.contentOffset.y)];
}

#pragma mark - UIButton animation

- (void)animateSendButtonInDirection:(Direction)direction
{
    float distance = 50.0f;
    float movement = ((direction == kDirectionUp) ? distance : -distance);
    float movementDuration = 0.2f;
    
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:movementDuration animations:^{
        
        self.buttonDistToBottom.constant += movement;
        [self.view layoutIfNeeded];
    }];
}

@end
