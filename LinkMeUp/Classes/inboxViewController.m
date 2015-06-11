//
//  inboxViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/2/14.
//
//

#import "inboxViewController.h"

#import <Parse/Parse.h>

#import "Constants.h"
#import "Link.h"
#import "linkTableViewCell.h"

#import "pushNotifViewController.h"

#import "sentLinkViewController.h"
#import "receivedLinkViewController.h"

@interface inboxViewController ()

@end

@implementation inboxViewController


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

#pragma mark - Badge count

- (void)updateInboxBadge
{
    // update tab bar badge
    int badgeCount = self.sharedData.sentLinkUpdates + self.sharedData.receivedLinkUpdates;
    [self.navigationController.tabBarItem setBadgeValue:(badgeCount ? [NSString stringWithFormat:@"%u", badgeCount] : nil)];
    
    // update app badge
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate updateApplicationBadge];
}

#pragma mark - Notification methods

- (void)applicationDidBecomeActive
{
    // received new link/message
    if (self.receivedPush)
    {
        [self startLoadingIndicator];
    }
    
    // if selected segment changed, reload table
    if (self.segControl.selectedSegmentIndex != self.selectedSegment)
    {
        self.segControl.selectedSegmentIndex = self.selectedSegment;
        [self.tableView reloadData];
    }
}

- (void)didFinishLoadingSentLinks
{
    // handle
}

- (void)didFinishLoadingReceivedLinks
{
    // handle
}

- (void)didFinishLoadingAllLinks
{
    NSLog(@"Did finish loading links");
    
    if (self.sentNewLink)
    {
        self.sentNewLink = NO;
        
        // present push notif screen, if applicable
        LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
        UIUserNotificationType remoteNotification = [appDelegate getEnabledNotificationTypes];
        
        BOOL didShowPushVC = [[[NSUserDefaults standardUserDefaults] objectForKey:kDidShowPushVCThisSession] boolValue];
        
        if (remoteNotification == UIRemoteNotificationTypeNone
            && [self.sharedData.me[kNumberPushRequests] integerValue] < PUSH_REQUESTS_LIMIT
            && !didShowPushVC)
        {
            [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(presentPushScreen) userInfo:nil repeats:NO];
        }
    }
    
    if (self.receivedPush)
        self.receivedPush = NO;
    
    // reload table
    [self.tableView reloadData];
    [self stopLoadingIndicator];
    
    // update badge count
    [self updateInboxBadge];
}

#pragma mark - View controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFinishLoadingSentLinks)
                                                     name:@"loadedSentLinks"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFinishLoadingReceivedLinks)
                                                     name:@"loadedReceivedLinks"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFinishLoadingAllLinks)
                                                     name:@"loadedAllLinks"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // initialize table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // customize segmented control
    NSArray *views = [self.segControl subviews];
    //[[views objectAtIndex:0] setTintColor:[UIColor yellowColor]];
    [[views objectAtIndex:0] setTintColor:FAINT_BLUE];
    [[views objectAtIndex:1] setTintColor:FAINT_GREEN];
    [self.segControl addTarget:self action:@selector(segChanged:) forControlEvents:UIControlEventValueChanged];
    
    // refresh control
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.tag = @"Refresh Control";
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    [refresh addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview: refresh];
}

- (void)viewWillAppear:(BOOL)animated
{
    // if refreshing, continue...
    UIRefreshControl *refreshControl = (UIRefreshControl *)[self.tableView viewWithTag:@"Refresh Control"];
    if (refreshControl.refreshing)
    {
        [self continueLoadingIndicator];
    }
    
    // if selected segment changed, reload table
    if (self.segControl.selectedSegmentIndex != self.selectedSegment)
    {
        self.segControl.selectedSegmentIndex = self.selectedSegment;
        [self.tableView reloadData];
    }
    
    // just sent song or received new links/messages
    if (self.sentNewLink || self.receivedPush)
    {
        [self startLoadingIndicator];
    }
    
    // if loading data
    else if (!self.sharedData.loadedSentLinks || !self.sharedData.loadedReceivedLinks)
    {
        // if first time loading data, showing loading status
        if ([self.sharedData.sentLinkData count] == 0 || [self.sharedData.receivedLinkData count] == 0)
            [self startLoadingIndicator];
    }
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadedSentLinks" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadedReceivedLinks" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadedAllLinks" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"applicationDidBecomeActive" object:nil];
}

#pragma mark - Present push notification view controller

- (void)presentPushScreen
{
    pushNotifViewController *pnvc = [[pushNotifViewController alloc] init];
    [self presentViewController:pnvc animated:YES completion: nil];
}

#pragma mark - Table view refresh

- (void)refresh:(UIRefreshControl *)refreshControl
{
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing"];
    
    // load data on user refresh
    if (self.sharedData.loadedReceivedLinks && self.sharedData.loadedSentLinks)
    {
        //*LOW PRIORITY UPDATE*
        [self.sharedData loadReceivedLinks: kPriorityLow];
        [self.sharedData loadSentLinks: kPriorityLow];
    }
}

- (void)startLoadingIndicator
{
    UIRefreshControl *refreshControl = (UIRefreshControl *)[self.tableView viewWithTag:@"Refresh Control"];
    
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Loading"];
    [refreshControl beginRefreshing];
    [self.tableView setContentOffset:CGPointMake(0, -refreshControl.frame.size.height) animated:YES];
}

- (void)stopLoadingIndicator
{
    UIRefreshControl *refreshControl = (UIRefreshControl *)[self.tableView viewWithTag:@"Refresh Control"];
    
    if (refreshControl.refreshing)
    {
        [refreshControl endRefreshing];
        [self.tableView setContentOffset:CGPointMake(0, 0)];
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@""];
    }
}

- (void)continueLoadingIndicator
{
    UIRefreshControl *refreshControl = (UIRefreshControl *)[self.tableView viewWithTag:@"Refresh Control"];
    
    [refreshControl endRefreshing];
    [refreshControl beginRefreshing];
    [self.tableView setContentOffset:CGPointMake(0, -refreshControl.frame.size.height) animated:YES];
}

/*#pragma mark - Swipe gestures

- (IBAction)swipeLeft:(id)sender
{
    UITabBarController *myTBC = (UITabBarController *)[self.navigationController parentViewController];
    myTBC.selectedViewController = myTBC.viewControllers[kTabBarIconMessenger];
}*/

#pragma mark - UI action methods

- (void)segChanged:(id)sender
{
    [self.tableView reloadData];
    self.selectedSegment = (InboxSegments)self.segControl.selectedSegmentIndex;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (self.segControl.selectedSegmentIndex == kInboxSent)
    {
        return [self.sharedData.sentLinkData count];
    }
    
    else //if (self.segControl.selectedSegmentIndex == kInboxReceived)
    {
        return [self.sharedData.receivedLinkData count];
    }
    
    /*else // starred tracks
    {
        return 0;
    }*/
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    if (self.segControl.selectedSegmentIndex == kInboxSent)
    {
        CellIdentifier = @"Sent Link";
    }
    else //if (self.segControl.selectedSegmentIndex == kInboxReceived)
    {
        CellIdentifier = @"Received Link";
    }
    /*else
    {
        CellIdentifier = @"Starred Tracks";
    }*/
    
    linkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[linkTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (self.segControl.selectedSegmentIndex == kInboxSent)
    {
        // data
        Link *link = [self.sharedData.sentLinkData[indexPath.row] objectForKey:@"link"];
        UIImage *albumArt = [self.sharedData.sentLinkData[indexPath.row] objectForKey:@"art"];
        
        // set background color/status based on update status
        switch ([link.lastReceiverUpdate integerValue])
        {
            case kLastUpdateNoUpdate:
            {
                cell.backgroundColor = FAINT_GRAY;
                cell.statusLabel.text = @"";
                break;
            }
                
            case kLastUpdateNewMessage:
            {
                cell.backgroundColor = FAINT_BLUE;
                cell.statusLabel.text = @"New msg";
                break;
            }
                
            case kLastUpdateNewLike:
            {
                cell.backgroundColor = FAINT_BLUE;
                cell.statusLabel.text = @"Liked!";
                break;
            }
                
            case kLastUpdateNewLove:
            {
                cell.backgroundColor = FAINT_BLUE;
                cell.statusLabel.text = @"Loved!";
                break;
            }
                
            default:
                break;
        }
        
        // labels        
        cell.contactLabel.text = [Constants stringForArray:self.sharedData.sentLinkData[indexPath.row][@"contacts"] withKey:@"name"];
        cell.dateLabel.text = [Constants dateToString:link.lastReceiverUpdateTime];
        
        if (link.isSong)
            cell.songInfoLabel.text = [[link.title stringByAppendingString:@" | "] stringByAppendingString:link.artist];
        
        else cell.songInfoLabel.text = link.title;
        
        // album art
        [self displayAlbumArt:albumArt inCell:cell];
    }
    
    else //if (self.segControl.selectedSegmentIndex == kInboxReceived)
    {
        // data
        Link *link = [self.sharedData.receivedLinkData[indexPath.row] objectForKey:@"link"];
        PFUser *sender = [self.sharedData.receivedLinkData[indexPath.row] objectForKey:@"contacts"];
        UIImage *albumArt = [self.sharedData.receivedLinkData[indexPath.row] objectForKey:@"art"];
        
        // set background color/status based on update status
        NSMutableDictionary *receiverData = [self.sharedData receiverDataForUserId: self.sharedData.me.objectId inLink:link];
        NSNumber *lastSenderUpdate = [receiverData objectForKey:@"lastSenderUpdate"];
        NSDate *lastSenderUpdateTime = [receiverData objectForKey:@"lastSenderUpdateTime"];
  
        switch ([lastSenderUpdate integerValue])
        {
            case kLastUpdateNoUpdate:
            {
                cell.backgroundColor = FAINT_GRAY;
                cell.statusLabel.text = @"";
                break;
            }
             
            case kLastUpdateNewLink:
            {
                cell.backgroundColor = FAINT_GREEN;
                cell.statusLabel.text = @"New link!";
                break;
            }
                
            case kLastUpdateNewMessage:
            {
                cell.backgroundColor = FAINT_GREEN;
                cell.statusLabel.text = @"New msg";
                break;
            }
                
            default:
                break;
        }
        
        // labels
        cell.contactLabel.text = [Constants nameElseUsername:sender];
        cell.dateLabel.text = [Constants dateToString:lastSenderUpdateTime];
        
        if (link.isSong)
            cell.songInfoLabel.text = [[link.title stringByAppendingString:@" | "] stringByAppendingString:link.artist];
        
        else cell.songInfoLabel.text = link.title;
        
        // album art
        [self displayAlbumArt:albumArt inCell:cell];
    }
    
    /*else // starred tracks
    {
        
    }*/
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return LINKS_ROW_HEIGHT;
}

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    linkTableViewCell *cell = (linkTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    switch (self.segControl.selectedSegmentIndex)
    {
        case kInboxReceived:
        {
            self.sharedData.selectedLink = [self.sharedData.receivedLinkData[indexPath.row] objectForKey:@"link"];
            receivedLinkViewController *rlvc = [[receivedLinkViewController alloc] initWithNibName:@"linkViewController" bundle:nil];
            
            // mark local copy as seen
            if (![self.sharedData receivedLinkSeen:self.sharedData.selectedLink])
            {
                // update table view cell
                cell.statusLabel.text = @"";
                cell.backgroundColor = FAINT_GRAY;
                
                // decrement tab bar badge count
                self.sharedData.receivedLinkUpdates--;
                [self updateInboxBadge];
            }
            
            // push received link VC
            [self.navigationController pushViewController:rlvc animated:YES];
            
            break;
        }
            
        case kInboxSent:
        {
            self.sharedData.selectedLink = [self.sharedData.sentLinkData[indexPath.row] objectForKey:@"link"];
            sentLinkViewController *slvc = [[sentLinkViewController alloc] initWithNibName:@"linkViewController" bundle:nil];
            
            // mark local copy as seen
            if (![self.sharedData sentLinkSeen:self.sharedData.selectedLink])
            {
                // update table view cell
                cell.statusLabel.text = @"";
                cell.backgroundColor = FAINT_GRAY;
                
                // decrement tab bar badge count
                self.sharedData.sentLinkUpdates--;
                [self updateInboxBadge];
            }
            
            // push sent link VC
            [self.navigationController pushViewController:slvc animated:YES];
            
            break;
        }
            
        /*case kInboxStarred:
            break;*/
            
        default:
            break;
    }
}

#pragma mark - UIGraphics helper methods

- (void)displayAlbumArt:(UIImage *)albumArt inCell:(UITableViewCell *)cell
{
    /* Resize, no crop
    [cell.imageView setImage:[UIImage imageWithCGImage:[albumArt CGImage]
                                       scale:albumArt.size.width/85.0f
                                           orientation:albumArt.imageOrientation]];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;*/
    
    // images
    UIImage *sourceImage = albumArt;
    UIImage *newImage = nil;
    
    // original size
    CGSize imageSize = sourceImage.size;
    
    // target size
    CGSize targetSize = CGSizeMake(85.0f, 85.0f);
    
    // scaling
    CGFloat scaleFactor = 0.0f;
    CGFloat scaledWidth = targetSize.width;
    CGFloat scaledHeight = targetSize.height;
    
    // origin
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    /*// target size exception
    if (imageSize.width / imageSize.height >= 85.0f/80.0f)
        targetSize = CGSizeMake(85.0f, 80.0f);*/
    
    // calculate scale factors
    CGFloat widthFactor = targetSize.width / imageSize.width;
    CGFloat heightFactor = targetSize.height / imageSize.height;
    
    // limiting dimension
    scaleFactor = (widthFactor > heightFactor ? widthFactor : heightFactor);
    scaledWidth  = imageSize.width * scaleFactor;
    scaledHeight = imageSize.height * scaleFactor;
    
    /*// center the image
    if (widthFactor > heightFactor)
        thumbnailPoint.y = (targetSize.height - scaledHeight) * 0.5;
    
    if (widthFactor < heightFactor)
        thumbnailPoint.x = (targetSize.width - scaledWidth) * 0.5;*/
    
    // crops image
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, UIScreen.mainScreen.scale);
    
    CGRect thumbnailRect;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // set imageview
    cell.imageView.image = newImage;
    
    // pop the context to get back to the default
    UIGraphicsEndImageContext();
}

@end
