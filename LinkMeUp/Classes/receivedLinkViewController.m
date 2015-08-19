//
//  receivedLinkViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/22/14.
//
//

#import "receivedLinkViewController.h"

#import "messagesTableViewCell.h"

@interface receivedLinkViewController ()
{
    // data loading status
    BOOL loadedLinkData;
}

@end

@implementation receivedLinkViewController


#pragma mark - Receiver data/messages

- (void)setData
{
    self.receiverData = [self.sharedData receiverDataForUserId:self.sharedData.me.objectId inLink:self.sharedData.selectedLink];
    self.messages = [self.receiverData objectForKey:@"messages"];
}

#pragma mark - Toolbar methods

- (void)messagesButtonPressed:(id)sender
{
    // initialize reply view controller
    self.replyVC = [[replyViewController alloc] init];
    
    self.replyVC.isLinkSender = NO;
    self.replyVC.receiverData = self.receiverData;
    self.replyVC.contactId = ((PFUser *)[self.sharedData.selectedLink objectForKey:@"sender"]).objectId;
    self.replyVC.messages = [self.receiverData objectForKey:@"messages"];
    
    [self.navigationController pushViewController:self.replyVC animated:YES];
}

- (void)likeButtonPressed:(id)sender
{
    UIBarButtonItem *toolbarButtonLike = [self.toolbar.items objectAtIndex:4]; // hardcoded constant!
    UIBarButtonItem *toolbarButtonLove = [self.toolbar.items objectAtIndex:6]; // hardcoded constant!
    
    UIButton *likeButton = (UIButton *)toolbarButtonLike.customView;
    UIButton *loveButton = (UIButton *)toolbarButtonLove.customView;
    
    BOOL shouldSendPush = NO;
    
    // link not currently "liked"
    if ([[self.receiverData objectForKey:@"liked"] boolValue] == NO)
    {
        likeButton.selected = YES;
        
        // if previously "loved", demote status
        if ([[self.receiverData objectForKey:@"loved"] boolValue] == YES)
        {
            loveButton.selected = NO;
        }
        
        // only send push if never liked/loved
        if (![self.receiverData objectForKey:@"timeLiked"] && ![self.receiverData objectForKey:@"timeLoved"])
        {
            shouldSendPush = YES;
        }
    }
    
    // link currently "liked"
    else
    {
        // demote status
        likeButton.selected = NO;
    }
    
    // update local copy
    [self likeLink:self.sharedData.selectedLink];
    [self setData];
    
    // retrieve link from Parse and update
    [self updateLinkWithReaction:kReactionLike sendPush:shouldSendPush];
}

- (void)loveButtonPressed:(id)sender
{
    UIBarButtonItem *toolbarButtonLike = [self.toolbar.items objectAtIndex:4]; // hardcoded constant!
    UIBarButtonItem *toolbarButtonLove = [self.toolbar.items objectAtIndex:6]; // hardcoded constant!
    
    UIButton *likeButton = (UIButton *)toolbarButtonLike.customView;
    UIButton *loveButton = (UIButton *)toolbarButtonLove.customView;
    
    BOOL shouldSendPush = NO;
    
    // link not currently "loved"
    if ([[self.receiverData objectForKey:@"loved"] boolValue] == NO)
    {
        loveButton.selected = YES;
        
        // if previously "liked", promote status!
        if ([[self.receiverData objectForKey:@"liked"] boolValue] == YES)
        {
            // link no longer just "liked"
            likeButton.selected = NO;
        }
        
        // only send push if never loved
        if (![self.receiverData objectForKey:@"timeLoved"])
        {
            shouldSendPush = YES;
        }
    }
    
    // link currently "loved"
    else
    {
        // demote status
        loveButton.selected = NO;
    }
    
    // update local copy
    [self loveLink:self.sharedData.selectedLink];
    [self setData];
    
    // retrieve link from Parse and update
    [self updateLinkWithReaction:kReactionLove sendPush:shouldSendPush];
}

#pragma mark - Like/love update methods

- (void)updateLinkWithReaction:(ReactionType)reaction sendPush:(BOOL)shouldSendPush
{
    PFUser *me = self.sharedData.me;
    NSString *senderId = self.sharedData.selectedLink.sender.objectId;
    
    PFQuery *linkQuery = [Link query];
    [linkQuery includeKey:@"sender"];
    [linkQuery getObjectInBackgroundWithId:self.sharedData.selectedLink.objectId block:^(PFObject *object, NSError *error) {
        if (!error)
        {
            // update server copy
            Link *link = (Link *)object;
            (reaction == kReactionLike ? [self likeLink:link] : [self loveLink:link]);
            
            // update local pointers, if applicable
            if ([self.sharedData.selectedLink.objectId isEqualToString:link.objectId])
            {
                self.sharedData.selectedLink = link;
                [self setData];
            }
            
            [link saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error)
                {
                    if (shouldSendPush)
                    {
                        // send push notification to link sender
                        NSString *channel = [NSString stringWithFormat:@"user_%@", senderId];
                        
                        NSString *alert = [NSString stringWithFormat:@"%@ %@ your link!", [Constants nameElseUsername:me], (reaction == kReactionLike ? @"liked" : @"loved")];
                        
                        NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:alert, @"Increment", @"emotion", [NSNumber numberWithBool:YES], nil]
                                                                                         forKeys:[NSArray arrayWithObjects:@"alert", @"badge", @"type", @"isSender", nil]];
                        
                        PFPush *newEmotionPush = [[PFPush alloc] init];
                        [newEmotionPush setChannel: channel];
                        [newEmotionPush setData:data];
                        [newEmotionPush sendPushInBackground];
                    }
                }
                
                else
                {
                    NSLog(@"Error posting like/love %@ %@", error, [error userInfo]);
                }
            }];
        }
        
        else
        {
            NSLog(@"Error retrieving link %@ %@", error, [error userInfo]);
        }
    }];
}

#pragma mark - receiversData update methods

- (void)likeLink:(Link *)link
{
    NSMutableDictionary *receiverData = [self.sharedData receiverDataForUserId:self.sharedData.me.objectId inLink:link];
    
    NSDate *now = [NSDate date];
    
    // link not currently "liked"
    if ([[receiverData objectForKey:@"liked"] boolValue] == NO)
    {
        receiverData[@"liked"] = [NSNumber numberWithBool:YES];
        receiverData[@"timeLiked"] = now;
        
        // if previously "loved", demote status but do not tell sender
        if ([[receiverData objectForKey:@"loved"] boolValue] == YES)
        {
            receiverData[@"loved"] = [NSNumber numberWithBool:NO];
        }
        
        else // tell sender!
        {
            // update status for sender
            link.lastReceiverUpdate = [NSNumber numberWithInt:kLastUpdateNewLike];
            link.lastReceiverUpdateTime = now;
            
            // update for sender's messages summary table
            receiverData[@"lastReceiverAction"] = [NSNumber numberWithInt:kLastActionLiked];
            receiverData[@"lastReceiverActionTime"] = now;
            receiverData[@"lastReceiverActionSeen"] = [NSNumber numberWithBool:NO];
        }
    }
    
    // link currently "liked"
    else
    {
        // demote staus but do not tell sender
        receiverData[@"liked"] = [NSNumber numberWithBool:NO];
    }
}

- (void)loveLink:(Link *)link
{
    NSMutableDictionary *receiverData = [self.sharedData receiverDataForUserId:self.sharedData.me.objectId inLink:link];
    
    NSDate *now = [NSDate date];
    
    // link not currently "loved"
    if ([[receiverData objectForKey:@"loved"] boolValue] == NO)
    {
        receiverData[@"loved"] = [NSNumber numberWithBool:YES];
        receiverData[@"timeLoved"] = now;
        
        // if previously "liked", promote status!
        if ([[receiverData objectForKey:@"liked"] boolValue] == YES)
        {
            // link no longer just "liked"
            receiverData[@"liked"] = [NSNumber numberWithBool:NO];
        }
        
        // update status for sender
        link.lastReceiverUpdate = [NSNumber numberWithInt:kLastUpdateNewLove];
        link.lastReceiverUpdateTime = now;
        
        // update for sender's messages summary table
        receiverData[@"lastReceiverAction"] = [NSNumber numberWithInt:kLastActionLoved];
        receiverData[@"lastReceiverActionTime"] = now;
        receiverData[@"lastReceiverActionSeen"] = [NSNumber numberWithBool:NO];
    }
    
    // link currently "loved"
    else
    {
        // demote status but do not tell sender
        receiverData[@"loved"] = [NSNumber numberWithBool:NO];
    }
}

#pragma mark - Load toolbar

- (void)loadToolbar
{
    // initialize icons
    UIButton *messagesButton = [super toolbarButtonWithNormalIcon:[UIImage imageNamed:@"glyphicons_244_conversation"]
                                                     selectedIcon:[UIImage imageNamed:@"glyphicons_244_conversation"]
                                                             text:@"Messages"
                                                           action:@selector(messagesButtonPressed:)];
    
    UIButton *forwardButton = [super toolbarButtonWithNormalIcon:[UIImage imageNamed:@"glyphicons_211_right_arrow"]
                                                    selectedIcon:[UIImage imageNamed:@"glyphicons_211_right_arrow"]
                                                            text:@"Forward"
                                                          action:@selector(forwardButtonPressed:)];
    
    UIButton *likeButton = [super toolbarButtonWithNormalIcon:[UIImage imageNamed:@"glyphicons_343_thumbs_up"]
                                                 selectedIcon:[UIImage imageNamed:@"glyphicons_343_thumbs_up_selected"]
                                                         text:@"Like"
                                                       action:@selector(likeButtonPressed:)];
    
    
    UIButton *loveButton = [super toolbarButtonWithNormalIcon:[UIImage imageNamed:@"glyphicons_019_heart_empty"]
                                                 selectedIcon:[UIImage imageNamed:@"glyphicons_012_heart"]
                                                         text:@"Love"
                                                       action:@selector(loveButtonPressed:)];
    
    // set button states
    likeButton.selected = [[self.receiverData objectForKey:@"liked"] boolValue];
    loveButton.selected = [[self.receiverData objectForKey:@"loved"] boolValue];
    
    // initialize toolbar buttons
    UIBarButtonItem *toolbarButtonMessages = [[UIBarButtonItem alloc] initWithCustomView:messagesButton];
    UIBarButtonItem *toolbarButtonForward = [[UIBarButtonItem alloc] initWithCustomView:forwardButton];
    
    UIBarButtonItem *toolbarButtonLike = [[UIBarButtonItem alloc] initWithCustomView:likeButton];
    UIBarButtonItem *toolbarButtonLove = [[UIBarButtonItem alloc] initWithCustomView:loveButton];

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // add buttons to toolbar
    [self.toolbar setItems: [NSArray arrayWithObjects: toolbarButtonMessages, flexibleSpace, toolbarButtonForward, flexibleSpace, toolbarButtonLike, flexibleSpace, toolbarButtonLove, nil]];
    
    [self.view addSubview: self.toolbar];
    
    // set toolbar autolayout constraints
    UIToolbar *toolbar = self.toolbar;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(toolbar);
    NSDictionary *metrics = @{@"toolbar_height":@49, @"tabbar_height":@49};
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[toolbar(toolbar_height)]-tabbar_height-|" options:0 metrics:metrics views:viewsDictionary];
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[toolbar]|" options:0 metrics:nil views:viewsDictionary];
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:verticalConstraints];
    [self.view addConstraints:horizontalConstraints];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kLinkYoutube)
        return 1;
    
    else // (section == kLinkMessages)
        return (loadedLinkData ? [[self.receiverData objectForKey:@"messages"] count] : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    
    if (indexPath.section == kLinkYoutube)
    {
        // delegate to superclass
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    else // (section == kLinkMessages)
    {
        CellIdentifier = @"Link - Message";
        
        messagesTableViewCell *cell = (messagesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil)
        {
            cell = [[messagesTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.contactLabel.text = [self.messages[indexPath.row] objectForKey:@"name"];
        cell.dateLabel.text = [Constants dateToString:[self.messages[indexPath.row] objectForKey:@"time"]];
        
        cell.messageTextLabel.text = [self.messages[indexPath.row] objectForKey:@"message"];
        
        return cell;
    }
}

#pragma mark - Link data load

- (void)loadUpdatedLink
{
    // update data in Parse
    PFQuery *linkQuery = [Link query];
    [linkQuery includeKey:@"sender"];
    [linkQuery getObjectInBackgroundWithId:self.sharedData.selectedLink.objectId block:^(PFObject *object, NSError *error) {
        if (!error)
        {
            NSLog(@"Loaded updated link");
            
            // mark link as seen
            Link *link = (Link *)object;
            [self.sharedData receivedLinkSeen:link];
            
            // if user is still viewing this link...
            if ([self.sharedData.selectedLink.objectId isEqualToString:link.objectId])
            {
                // update local pointers
                self.sharedData.selectedLink = link;
                [self setData];
                
                // reload table
                loadedLinkData = YES;
                [self.tableView reloadData];
                
                // initialize toolbar
                self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 382.0f, self.view.bounds.size.width, 49.0f)];
                self.toolbar.barTintColor = TURQ;
                self.toolbar.tintColor = [UIColor whiteColor];
                [self loadToolbar];
            }
            
            [self.sharedData.selectedLink saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error)
                {
                    NSLog(@"Error posting seen status %@ %@", error, [error userInfo]);
                }
            }];
        }
        
        else
        {
            NSLog(@"Error retrieving link %@ %@", error, [error userInfo]);
        }
    }];
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
    
    // load link messages
    loadedLinkData = NO;
    [self loadUpdatedLink];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // load receiver data/messages
    // (show any posts I made in replyVC)
    if (loadedLinkData)
    {
        [self setData];
        [self.tableView reloadData];
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
