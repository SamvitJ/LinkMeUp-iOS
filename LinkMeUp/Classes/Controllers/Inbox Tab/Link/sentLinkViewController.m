//
//  sentLinkViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/22/14.
//
//

#import "sentLinkViewController.h"

#import "messagesTableViewCell.h"

#import "likeloveStatusViewController.h"

@interface sentLinkViewController ()
{
    // data loading status
    BOOL loadedLinkData;
    
    // likes and loves
    int likeCount;
    int loveCount;
}

@end

@implementation sentLinkViewController


#pragma mark - Receiver data/messages

- (void)setData
{
    // load messages (receivers data)
    self.receiversData = [self.sharedData.selectedLink objectForKey:@"receiversData"];
    
    // sort messages by last update time (and then by name, if neccessary)
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"lastReceiverActionTime" ascending:NO];
    NSSortDescriptor *sortDescriptorName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: sortDescriptorDate, sortDescriptorName, nil];
    
    self.sortedData = [[NSMutableArray alloc] initWithArray:[self.receiversData sortedArrayUsingDescriptors:sortDescriptors]];

    // remove "me", if also sent to myself
    for (NSDictionary *receiver in self.sortedData)
    {
        if ([receiver[@"identity"] isEqualToString:@"me"])
        {
            [self.sortedData removeObject:receiver];
            break;
        }
    }
}

#pragma mark - Toolbar methods

- (void)messagesButtonPressed:(id)sender
{
    // if not text message and if receiversData not empty
    if (!self.sharedData.selectedLink.isText && [self.sortedData count])
    {
        [self.tableView setContentOffset:CGPointMake(0.0f, (self.sharedData.selectedLink.isSong ? YOUTUBE_LINK_ROW_HEIGHT + ITUNES_INFO_HEIGHT - 1.0f: YOUTUBE_LINK_ROW_HEIGHT - 1.0f)) animated:YES];
    }
}

- (void)likeButtonPressed:(id)sender
{
    if (likeCount == 0)
        return;
    
    NSMutableArray *likeData = [[NSMutableArray alloc] init];
    
    for (NSDictionary *receiverData in self.sortedData)
    {
        if ([[receiverData objectForKey:@"liked"] boolValue])
        {
            NSMutableDictionary *like = [[NSMutableDictionary alloc] init];
            
            if ([receiverData objectForKey:@"name"])
                like[@"name"] = [receiverData objectForKey:@"name"];
            
            if ([receiverData objectForKey:@"timeLiked"])
                like[@"time"] = [receiverData objectForKey:@"timeLiked"];
            
            [likeData addObject:like];
        }
    }
    
    likeloveStatusViewController *llsvc = [[likeloveStatusViewController alloc] init];
    llsvc.reaction = kReactionLike;
    llsvc.reactionData = likeData;
    
    [self.navigationController pushViewController:llsvc animated:YES];
}

- (void)loveButtonPressed:(id)sender
{
    if (loveCount == 0)
        return;
    
    NSMutableArray *loveData = [[NSMutableArray alloc] init];
    
    for (NSDictionary *receiverData in self.sortedData)
    {
        if ([[receiverData objectForKey:@"loved"] boolValue])
        {
            NSMutableDictionary *love = [[NSMutableDictionary alloc] init];
            
            if ([receiverData objectForKey:@"name"])
                love[@"name"] = [receiverData objectForKey:@"name"];
            
            if ([receiverData objectForKey:@"timeLoved"])
                love[@"time"] = [receiverData objectForKey:@"timeLoved"];
            
            [loveData addObject:love];
        }
    }
    
    likeloveStatusViewController *llsvc = [[likeloveStatusViewController alloc] init];
    llsvc.reaction = kReactionLove;
    llsvc.reactionData = loveData;
    
    [self.navigationController pushViewController:llsvc animated:YES];
}

#pragma mark - Load toolbar

- (void)loadToolbar
{
    // determine number of likes and loves
    likeCount = 0;
    loveCount = 0;
    for (NSDictionary *receiverData in self.receiversData)
    {
        if ([[receiverData objectForKey:@"liked"] boolValue])
            likeCount++;
        
        if ([[receiverData objectForKey:@"loved"] boolValue])
            loveCount++;
    }
    
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
                                                 selectedIcon:[UIImage imageNamed:@"glyphicons_343_thumbs_up"]
                                                         text:(likeCount == 1 ? [NSString stringWithFormat:@"%u Like", likeCount] : [NSString stringWithFormat:@"%u Likes", likeCount])
                                                       action:@selector(likeButtonPressed:)];
    
    
    UIButton *loveButton = [super toolbarButtonWithNormalIcon:[UIImage imageNamed:@"glyphicons_019_heart_empty"]
                                                 selectedIcon:[UIImage imageNamed:@"glyphicons_019_heart_empty"]
                                                         text:(loveCount == 1 ? [NSString stringWithFormat:@"%u Love", loveCount] : [NSString stringWithFormat:@"%u Loves", loveCount])
                                                       action:@selector(loveButtonPressed:)];
    
    // initialize toolbar buttons
    UIBarButtonItem *toolbarButtonMessages = [[UIBarButtonItem alloc] initWithCustomView:messagesButton];
    UIBarButtonItem *toolbarButtonForward = [[UIBarButtonItem alloc] initWithCustomView:forwardButton];
    
    UIBarButtonItem *toolbarButtonLike = [[UIBarButtonItem alloc] initWithCustomView:likeButton];
    UIBarButtonItem *toolbarButtonLove = [[UIBarButtonItem alloc] initWithCustomView:loveButton];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // add buttons to toolbar
    [self.toolbar setItems: [NSArray arrayWithObjects: toolbarButtonMessages, flexibleSpace, toolbarButtonForward, flexibleSpace, toolbarButtonLike, flexibleSpace, toolbarButtonLove, nil]];
    
    // add toolbar to view
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
    {
        if (self.sharedData.selectedLink.isText)
        {
            return (loadedLinkData ? 1 : 0);
        }
        
        else
        {
            return (loadedLinkData ? 1 + [self.sortedData count] : 0);
        }
    }
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
        if (indexPath.row == 0) // original caption
        {
            CellIdentifier = @"Link - Message - Annotation";
            
            messagesTableViewCell *cell = (messagesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            if (cell == nil)
            {
                cell = [[messagesTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            cell.contactLabel.text = [Constants nameElseUsername: self.sharedData.me];
            cell.dateLabel.text = [NSString stringWithFormat:@"%@", [Constants dateToString:[self.sharedData.selectedLink createdAt]]];
            cell.messageTextLabel.text = self.sharedData.selectedLink.annotation;
            
            return cell;
        }
        
        else
        {
            CellIdentifier = @"Link - Message - Conversation status";
            
            messagesTableViewCell *cell = (messagesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            if (cell == nil)
            {
                cell = [[messagesTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
                
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            NSString *receiverName = [self.sortedData[indexPath.row - 1] objectForKey:@"name"];
            
            NSNumber *lastAction = [self.sortedData[indexPath.row - 1] objectForKey:@"lastReceiverAction"];
            NSDate *lastActionTime = [self.sortedData[indexPath.row - 1] objectForKey:@"lastReceiverActionTime"];
            BOOL lastActionSeen = [[self.sortedData[indexPath.row - 1] objectForKey:@"lastReceiverActionSeen"] boolValue];
            
            // cell labels
            cell.contactLabel.text = [NSString stringWithFormat:@"%@", receiverName];
            cell.dateLabel.text = [Constants dateToString:lastActionTime];
            
            switch ([lastAction integerValue])
            {
                case kLastActionLoved:
                {
                    cell.messageTextLabel.text = [NSString stringWithFormat:@"%@ loved your link!", receiverName];
                    cell.messageTextLabel.textColor = (lastActionSeen ? DARK_BLUE_GRAY : DEEP_RED);
                    break;
                }
                    
                case kLastActionLiked:
                {
                    cell.messageTextLabel.text = [NSString stringWithFormat:@"%@ liked your link!", receiverName];
                    cell.messageTextLabel.textColor = (lastActionSeen ? DARK_BLUE_GRAY : MILD_AQUA);
                    break;
                }
                    
                case kLastActionResponded:
                {
                    cell.messageTextLabel.text = (lastActionSeen ? @"Click to respond" : @"New message");
                    cell.messageTextLabel.textColor = (lastActionSeen ? DARK_BLUE_GRAY : DEEP_PURPLE);
                    break;
                }
                    
                case kLastActionSeen:
                {
                    cell.messageTextLabel.text = @"Seen";
                    cell.messageTextLabel.textColor = DARK_BLUE_GRAY;
                    break;
                }
                    
                case kLastActionNoAction:
                {
                    BOOL responded = [[self.sortedData[indexPath.row - 1] objectForKey:@"responded"] boolValue];
                    BOOL seen = [[self.sortedData[indexPath.row - 1] objectForKey:@"seen"] boolValue];
                    
                    if (responded)
                    {
                        cell.messageTextLabel.text = @"You replied";
                        cell.messageTextLabel.textColor = DARK_BLUE_GRAY;
                    }
                    
                    else if (seen)
                    {
                        cell.messageTextLabel.text = @"Awaiting response";
                        cell.messageTextLabel.textColor = DARK_BLUE_GRAY;
                    }
                    
                    else
                    {
                        cell.messageTextLabel.text = [NSString stringWithFormat:@"Not yet seen"];
                        cell.messageTextLabel.textColor = DARK_BLUE_GRAY;
                        
                        // if not yet seen, clear date label
                        cell.dateLabel.text = @"";
                    }
                    
                    break;
                }
                    
                default:
                    break;
            }
            
            return cell;
        }
    }
}

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kLinkMessages && indexPath.row >= 1)
    {
        // mark last receiver action as seen (local copy)
        NSString *contactId = [self.sortedData[indexPath.row - 1] objectForKey:@"identity"];
        NSMutableDictionary *receiverData = [self.sharedData receiverDataForUserId:contactId inLink:self.sharedData.selectedLink];
        receiverData[@"lastReceiverActionSeen"] = [NSNumber numberWithBool:YES];
        
        // update data in Parse
        PFQuery *linkQuery = [Link query];
        [linkQuery includeKey:@"sender"];
        [linkQuery getObjectInBackgroundWithId:self.sharedData.selectedLink.objectId block:^(PFObject *object, NSError *error) {
            if (!error)
            {
                // update server copy
                Link *link = (Link *)object;
                NSMutableDictionary *receiverData = [self.sharedData receiverDataForUserId:contactId inLink:link];
                receiverData[@"lastReceiverActionSeen"] = [NSNumber numberWithBool:YES];
                
                // update local pointers, if applicable
                if ([self.sharedData.selectedLink.objectId isEqualToString:link.objectId])
                {
                    self.sharedData.selectedLink = link;
                    [self setData];
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
        
        // initialize reply view controller
        self.replyVC = [[replyViewController alloc] init];
        
        self.replyVC.isLinkSender = YES;
        self.replyVC.receiverData = self.sortedData[indexPath.row - 1];
        self.replyVC.contactId = [self.sortedData[indexPath.row - 1] objectForKey:@"identity"];
        self.replyVC.messages = [self.sortedData[indexPath.row - 1] objectForKey:@"messages"];
        
        [self.navigationController pushViewController:self.replyVC animated:YES];
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
            [self.sharedData sentLinkSeen:link];
            
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
        // custom initialization
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
