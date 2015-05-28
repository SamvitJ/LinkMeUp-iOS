//
//  friendsViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/2/14.
//
//

#import "friendsViewController.h"

#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>

#import "Constants.h"
#import "FriendRequest.h"

#import "settingsViewController.h"

@interface friendsViewController ()

@end

@implementation friendsViewController


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

#pragma mark - Search display delegate methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

#pragma mark - Search bar delegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // show loading indicator
    UIRefreshControl *searchRC = (UIRefreshControl *)[self.searchDisplayController.searchResultsTableView viewWithTag:@"Search Refresh Control"];
    [searchRC beginRefreshing];
    
    // username queries
    PFQuery *usernameQuery = [PFUser query];
    [usernameQuery whereKey:@"username" equalTo:searchBar.text];
    
    PFQuery *usernameCapitalizedQuery = [PFUser query];
    [usernameCapitalizedQuery whereKey:@"username" equalTo:[searchBar.text capitalizedString]];
    
    PFQuery *usernameLowerCaseQuery = [PFUser query];
    [usernameLowerCaseQuery whereKey:@"username" equalTo:[searchBar.text lowercaseString]];
    
    // email queries
    PFQuery *emailQuery = [PFUser query];
    [emailQuery whereKey:@"email" equalTo:searchBar.text];
    
    PFQuery *emailCapitalizedQuery = [PFUser query];
    [emailCapitalizedQuery whereKey:@"email" equalTo:[searchBar.text capitalizedString]];
    
    PFQuery *emailLowerCaseQuery = [PFUser query];
    [emailLowerCaseQuery whereKey:@"email" equalTo:[searchBar.text lowercaseString]];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[usernameQuery, usernameCapitalizedQuery, usernameLowerCaseQuery,
                                                      emailQuery, emailCapitalizedQuery, emailLowerCaseQuery]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error)
        {
            [searchRC endRefreshing];
            
            for (PFUser *user in objects)
            {
                // check if user is contained in existing records
                BOOL isContained = NO;
                for (PFUser *existing in self.allContacts)
                {
                    if ([user.objectId isEqualToString:existing.objectId])
                    {
                        isContained = YES;
                    }
                }
                
                // if not contained, add user and reload table
                if (!isContained)
                {
                    [self.allContacts addObject:user];
                    [self.searchResults addObject:user];
                    [self.searchDisplayController.searchResultsTableView reloadData];
                }
            }
        }
        
        else
        {
            NSLog(@"Error loading users matching search query %@", [error userInfo]);
        }
    }];
}

#pragma mark - Search filtering

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
    // Clear previous search results
    [self.searchResults removeAllObjects];
    
    // Filter results using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.username contains[c] %@ OR SELF.name contains[c] %@ OR SELF.email contains[c] %@", searchText, searchText, searchText];
    
    self.allContacts = [[NSMutableArray alloc] init];
    [self.allContacts addObjectsFromArray:self.sharedData.requestSenders];
    [self.allContacts addObjectsFromArray:self.sharedData.myFriends];
    [self.allContacts addObjectsFromArray:self.sharedData.suggestedFriends];
    
    self.searchResults = [NSMutableArray arrayWithArray:[self.allContacts filteredArrayUsingPredicate:predicate]];
}

#pragma mark - Badge count

- (void)updateFriendsBadge
{
    // update tab bar badge
    int badgeCount = self.sharedData.sentRequestUpdates + self.sharedData.receivedRequestUpdates;
    [self.navigationController.tabBarItem setBadgeValue:(badgeCount ? [NSString stringWithFormat:@"%u", badgeCount] : nil)];
    
    // update app badge
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate updateApplicationBadge];
}

- (void)resetFriendsBadge
{
    // mark all received friend requests as seen
    for (FriendRequest *request in self.sharedData.friendRequests)
    {
        if ([[request objectForKey:@"seen"] boolValue] == NO)
        {
            request.seen = YES;
            [request saveInBackground];
        }
    }
    
    // reset update count
    self.sharedData.receivedRequestUpdates = 0;
    self.sharedData.sentRequestUpdates = 0;
    
    // tab bar badge count
    [self updateFriendsBadge];
}

#pragma mark - Notification methods

- (void)applicationDidBecomeActive
{
    // received new friend request
    if (self.receivedPush)
    {
        [self startLoadingIndicator];
    }
}

- (void)didFinishLoadingFriendRequests
{
    // handle
}

- (void)didFinishLoadingFriendList
{
    // handle
}

- (void)didFinishLoadingConnections
{
    if (self.receivedPush)
        self.receivedPush = NO;
    
    // reload tables
    [self.tableView reloadData];
    [self.searchDisplayController.searchResultsTableView reloadData];
    [self stopLoadingIndicator];
    
    // if friends VC selected, reset badge count
    UITabBarController *myTBC = (UITabBarController *)[self.navigationController parentViewController];
    (myTBC.selectedIndex == kTabBarIconFriends ? [self resetFriendsBadge] : [self updateFriendsBadge]);
}

#pragma mark - View controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFinishLoadingFriendRequests)
                                                     name:@"loadedFriendRequests"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFinishLoadingFriendList)
                                                     name:@"loadedFriendList"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFinishLoadingConnections)
                                                     name:@"loadedConnections"
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
    // Do any additional setup after loading the view from its nib.

    // initialize table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // initialize suggestion and request buttons
    self.requestButtons = [[NSMutableArray alloc] init];
    self.suggestionButtons = [[NSMutableArray alloc] init];
    
    // initialize search result contacts
    self.searchResults = [[NSMutableArray alloc] init];
    self.allContacts = [[NSMutableArray alloc] init];
    
    // initialize external request info
    self.userSearchButtons = [[NSMutableArray alloc] init];
    self.userSearchContacts = [[NSMutableArray alloc] init];
    
    // refresh control for main table
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.tag = @"Refresh Control";
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    [refresh addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refresh];
    
    // refresh control for search results table
    UIRefreshControl *searchRC = [[UIRefreshControl alloc] init];
    searchRC.tag = @"Search Refresh Control";
    searchRC.attributedTitle = [[NSAttributedString alloc] initWithString:@"Searching..."];
    [self.searchDisplayController.searchResultsTableView addSubview:searchRC];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // update friend suggestions section state
    self.showFriendSuggestions = self.sharedData.isLinkedWithFB;
    
    // if refreshing, continue...
    UIRefreshControl *refreshControl = (UIRefreshControl *)[self.tableView viewWithTag:@"Refresh Control"];
    if (refreshControl.refreshing)
    {
        [self continueLoadingIndicator];
    }
    
    // received friend request push
    if (self.receivedPush)
    {
        [self startLoadingIndicator];
    }
    
    // if loading data
    else if (!self.sharedData.loadedConnections)
    {
        // if first time loading data, showing loading status
        if ([self.sharedData.requestSenders count] == 0 && [self.sharedData.myFriends count] == 0 && [self.sharedData.suggestedFriends count] == 0)
            [self startLoadingIndicator];
    }
    
    // if not loading data, reset badge count
    else
    {
        [self resetFriendsBadge];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    // settings button
    UIButton *settingsButton = [self createSettingsButton];
    [settingsButton addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:settingsButton];
}

- (void)dealloc
{
    // set delegates to nil
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    
    // unsubscribe to notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadedFriendRequests" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadedFriendList" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadedConnections" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"applicationDidBecomeActive" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view refresh

- (void)refresh:(UIRefreshControl *)refreshControl
{
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing"];

    // load data on user refresh
    // *LOW PRIORITY UPDATES*
    if (self.sharedData.loadedConnections)
    {
        [self.sharedData loadConnections];
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

#pragma mark - Setting button

- (void)settingsButtonPressed:(id)sender
{
    [self.navigationController pushViewController:[[settingsViewController alloc] init] animated:YES];
}

/*#pragma mark - Swipe gestures

- (IBAction)swipeRight:(id)sender
{
    // swipe right to messenger tab
    UITabBarController *myTBC = (UITabBarController *)[self.navigationController parentViewController];
    myTBC.selectedViewController = myTBC.viewControllers[kTabBarIconMessenger];
}*/

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 1;
    
    else return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return [self.searchResults count];
    }
    
    else
    {
        if (section == kFriendsRequests)
            return [self.sharedData.requestSenders count];
        
        else if (section == kFriendsSuggestions)
            return [self.sharedData.suggestedFriends count];
            //return (self.showFriendSuggestions ? [self.sharedData.suggestedFriends count] : 1);
        
        else if (section == kFriendsCurrent)
            return [self.sharedData.myFriends count];
        
        else return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        static NSString *CellIdentifier;
        SearchResultsType *type;
        
        PFUser *displayPerson = self.searchResults[indexPath.row];
        
        if ([self.sharedData.requestSenders indexOfObject:displayPerson] != NSNotFound)
        {
            CellIdentifier = @"Search Results | Requests";
            type = kSearchResultsRequests;
        }
        
        else if ([self.sharedData.suggestedFriends indexOfObject:displayPerson] != NSNotFound)
        {
            CellIdentifier = @"Search Results | Suggestions";
            type = kSearchResultsSuggestions;
        }
        
        else if ([self.sharedData.myFriends indexOfObject:displayPerson] != NSNotFound)
        {
            CellIdentifier = @"Search Results | Friends";
            type = kSearchResultsFriends;
        }
        
        else
        {
            CellIdentifier = @"Search Results | New Contact";
            type = kSearchResultsNew;
        }
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = GILL_20;
        
        NSUInteger index;
        switch ((int)type)
        {
            case kSearchResultsRequests:
            {
                cell.backgroundColor = FAINT_PURPLE;
                cell.textLabel.text = [Constants nameElseUsername:displayPerson];
                
                index = [self.sharedData.requestSenders indexOfObject:displayPerson];
                [cell.contentView addSubview:self.requestButtons[index]];
                
                break;
            }
 
            case kSearchResultsSuggestions:
            {
                cell.backgroundColor = FAINT_GREEN;
                cell.textLabel.text = [Constants nameElseUsername:displayPerson];
                
                index = [self.sharedData.suggestedFriends indexOfObject:displayPerson];
                [cell.contentView addSubview:self.suggestionButtons[index]];
                
                break;
            }
                
            case kSearchResultsFriends:
            {
                cell.backgroundColor = FAINT_BLUE;
                cell.textLabel.text = [Constants nameElseUsername:displayPerson];
                
                index = [self.sharedData.myFriends indexOfObject:displayPerson];
                
                break;
            }
                
            case kSearchResultsNew:
            {
                cell.backgroundColor = FAINT_GREEN;
                cell.textLabel.text = [displayPerson objectForKey:@"username"];
                
                BOOL isPending = NO;
                BOOL hasButton = NO;
                
                // if request pending, show selected state
                for (PFUser *pending in self.sharedData.pendingRequests)
                {
                    if ([pending.objectId isEqualToString:displayPerson.objectId])
                    {
                        isPending = YES;
                        
                        // check if button exists for user
                        for (int i = 0; i < [self.userSearchContacts count]; i++)
                        {
                            PFUser *contact = self.userSearchContacts[i];
                            
                            // if so, add existing button to cell
                            if ([displayPerson.objectId isEqualToString:contact.objectId])
                            {
                                //NSLog(@"Pending, and button exists");
                                hasButton = YES;
                                
                                [cell.contentView addSubview:self.userSearchButtons[i]];
                            }
                        }
                        
                        // if not, create new button, set state, and add to cell
                        if (!hasButton)
                        {
                            //NSLog(@"Pending, but no button");
                            
                            UIButton *button = [self createSuggestionButton];
                            button.tag = -1 * ([self.userSearchButtons count] + 1); // clever indexing (see didPressAddFriendButtonAction:)
                            
                            button.selected = YES;
                            
                            [self.userSearchButtons addObject:button];
                            [self.userSearchContacts addObject:displayPerson];
                            
                            [cell.contentView addSubview:button];
                        }
                    }
                }
                
                if (!isPending)
                {
                    //NSLog(@"New search");
                    
                    UIButton *button = [self createSuggestionButton];
                    button.tag = -1 * ([self.userSearchButtons count] + 1); // clever indexing (see didPressAddFriendButtonAction:)
                    
                    // store result of search
                    self.lastSearch = displayPerson;
                    
                    [cell.contentView addSubview:button];
                    
                    break;
                }
            }
                
            default:
                break;
        }
    
        return cell;
    }
    
    else
    {
        static NSString *CellIdentifier;
        
        if (indexPath.section == kFriendsRequests)
        {
            CellIdentifier = @"Friend Requests";
        }
        else if (indexPath.section == kFriendsSuggestions /*&& self.showFriendSuggestions*/)
        {
            CellIdentifier = @"Suggestions";
        }
        /*else if (indexPath.section == kFriendsSuggestions && !self.showFriendSuggestions)
        {
            CellIdentifier = @"Link With FB Option";
        }*/
        else if (indexPath.section == kFriendsCurrent)
        {
            CellIdentifier = @"Friends";
        }
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = GILL_20;
        
        if (indexPath.section == kFriendsRequests)
        {
            // request senders
            PFUser *displayPerson = self.sharedData.requestSenders[indexPath.row];
            cell.textLabel.text = [Constants nameElseUsername:displayPerson];
            cell.backgroundColor = FAINT_PURPLE;
            
            // "accept request" button
            UIButton *button = [self createRequestButton];
            button.tag = indexPath.row;
            
            // add to array
            self.requestButtons[indexPath.row] = button;
            
            // add "accept request" button to cell
            [cell.contentView addSubview: self.requestButtons[indexPath.row]];
        }
        
        else if (indexPath.section == kFriendsSuggestions /*&& self.showFriendSuggestions*/) // load FB friend suggestions
        {
            PFUser *displayPerson = self.sharedData.suggestedFriends[indexPath.row];
            cell.textLabel.text = [Constants nameElseUsername:displayPerson];
            cell.backgroundColor = FAINT_GREEN;
            
            // "add friend" button
            UIButton *button = [self createSuggestionButton];
            button.tag = indexPath.row;
            
            // if request pending, show selected state
            for (PFUser *pending in self.sharedData.pendingRequests)
            {
                if ([pending.objectId isEqualToString:displayPerson.objectId])
                {
                    button.selected = YES;
                }
            }
            
            // add to array
            self.suggestionButtons[indexPath.row] = button;
            
            // add "add friend" button to cell
            [cell.contentView addSubview: self.suggestionButtons[indexPath.row]];
        }
        
        /*else if (indexPath.section == kFriendsSuggestions && !self.showFriendSuggestions) // offer link with FB option
        {
            cell.backgroundColor = FAINT_GREEN;
            
            // add link with FB button and label
            if (!self.facebookButton) self.facebookButton = [self createFacebookButton];
            if (!self.facebookLabel) self.facebookLabel = [self createFacebookLabel];
            
            // add link with FB button and label to cell
            [cell.contentView addSubview: self.facebookButton];
            [cell.contentView addSubview: self.facebookLabel];
        }*/
        
        else if (indexPath.section == kFriendsCurrent)
        {
            // current friends
            PFUser *displayPerson = self.sharedData.myFriends[indexPath.row];
            cell.textLabel.text = [Constants nameElseUsername:displayPerson];
            cell.backgroundColor = FAINT_BLUE;
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        return cell;
    }
}

#pragma mark - Table view action

// user chose to link account with FB
- (void)didLinkWithFB:(id)sender
{
    NSLog(@"Linking accounts...");

    PFUser *me = self.sharedData.me;
    [PFFacebookUtils linkUser:me
                  permissions:@[ @"public_profile", @"user_friends", @"email"]
                        block:^(BOOL succeeded, NSError *error) {
        if (!error)
        {
            // get the user's data from Facebook
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *fbUser, NSError *error)
             {
                 NSLog(@"Linked your facebook account!");
                 
                 // *HIGH PRIORITY UPDATES*
                 [self.sharedData updateLinkWithFacebookStatus];
                 [self.sharedData loadConnections];
                 
                 // critical info
                 me[@"facebook_id"] = fbUser.objectID;
                 me[@"name"] = [[fbUser.first_name stringByAppendingString:@" "] stringByAppendingString:fbUser.last_name];
                 
                 // supplemental info
                 me[@"first_name"] = fbUser.first_name;
                 me[@"facebook_email"] = [fbUser objectForKey:@"email"];;
                 
                 [me saveInBackground];
             }];
        }
        
        else
        {
            if ([[[error userInfo] objectForKey:@"code"] isEqualToNumber:@208])
            {
                NSString *message = @"Another user is already linked to this facebook id.";
                [[[UIAlertView alloc] initWithTitle:@"Already linked"
                                            message:message
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil, nil] show];
            }
            
            NSLog(@"Error linking accounts %@ %@", error, [error userInfo]);
            
            self.showFriendSuggestions = NO;
            [self.tableView reloadData];
        }
    }];
    
    self.showFriendSuggestions = YES;
    [self.tableView reloadData];
}

// accept pressed
- (void)didPressAcceptButtonAction:(id)sender
{
    UIButton *clicked = (UIButton *)sender;
    int index = (int)clicked.tag;
    
    // if button is not selected
    if (!clicked.selected)
    {
        // mark button as selected
        clicked.selected = YES;
        
        // accepted friend
        FriendRequest *request = self.sharedData.friendRequests[index];
        PFUser *acceptedFriend = self.sharedData.requestSenders[index];
        
        // modify data model to reflect user action
        [self.sharedData.myFriends addObject: acceptedFriend];
        [self.sharedData.friendRequests removeObjectAtIndex:index];
        [self.sharedData.requestSenders removeObjectAtIndex:index];
        
        // reload tables
        [self.tableView reloadData];
        [self.searchDisplayController.searchResultsTableView reloadData];
        
        // accept friend request
        PFUser *me = self.sharedData.me;
        request.accepted = YES;
        [request saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error)
            {
                // send push notification to sender
                NSString *alert = [NSString stringWithFormat:@"%@ accepted your friend request", [Constants nameElseUsername:me]];
                NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:alert, @"Increment", @"request", nil]
                                                                                 forKeys:[NSArray arrayWithObjects:@"alert", @"badge", @"type", nil]];
                
                PFPush *newRequestPush = [[PFPush alloc] init];
                [newRequestPush setChannel:[NSString stringWithFormat:@"user_%@", acceptedFriend.objectId]];
                [newRequestPush setData:data];
                [newRequestPush sendPushInBackground];
            }
            
            else
            {
                // Log details of the failure
                NSLog(@"Error marking request as accepted %@ %@", error, [error userInfo]);
            }
        }];
        
        // add sender to friends list
        PFRelation *myFriends = [me relationForKey:@"friends"];
        [myFriends addObject:acceptedFriend];
        
        [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error)
            {
                // Log details of the failure
                NSLog(@"Error adding new friend %@ %@", error, [error userInfo]);
            }
        }];
    }
}

// add friend/cancel request pressed
- (void)didPressAddFriendButtonAction:(id)sender
{
    UIButton *clicked = (UIButton *)sender;
    int index = (int)clicked.tag;
    
    // if button is not selected
    if (!clicked.selected)
    {
        clicked.selected = YES;
        
        PFUser *receiver;
        
        // suggestions list
        if (index >= 0)
        {
            receiver = self.sharedData.suggestedFriends[index];
        }
        
        // username search
        else
        {
            receiver = self.lastSearch;
            
            [self.userSearchButtons addObject:clicked];
            [self.userSearchContacts addObject:receiver];
        }
        
        [self.sharedData.pendingRequests addObject:receiver];
        
        // create friend request
        PFUser *me = self.sharedData.me;
        FriendRequest *request = [[FriendRequest alloc] init];
        request.sender = me;
        request.receiver = receiver;
        request.seen = NO;
        request.accepted = NO;
        
        PFACL *pairACL = [PFACL ACL];
        
        [pairACL setReadAccess:YES forUser:me];
        [pairACL setWriteAccess:YES forUser:me];
        [pairACL setReadAccess:YES forUser:receiver];
        [pairACL setWriteAccess:YES forUser:receiver];
        
        request.ACL = pairACL;
        [request saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error)
            {
                // send push notification to recipient
                NSString *alert = [NSString stringWithFormat:@"New friend request"];
                NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:alert, @"Increment", @"request", nil]
                                                                                 forKeys:[NSArray arrayWithObjects:@"alert", @"badge", @"type", nil]];
                
                PFPush *newRequestPush = [[PFPush alloc] init];
                [newRequestPush setChannel:[NSString stringWithFormat:@"user_%@", receiver.objectId]];
                [newRequestPush setData:data];
                [newRequestPush sendPushInBackground];
            }
        
            else
            {
                NSLog(@"Error saving friend request %@ %@", error, [error userInfo]);
            }
        }];
    }
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return [[UIView alloc] init];
    }
    
    else
    {
        UIView *view = [[UIView alloc] init];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 5.0f, tableView.frame.size.width, 20.0f)];
        
        [label setFont:[UIFont boldSystemFontOfSize:16]];
        
        if (section == kFriendsRequests)
            [label setText:@"Friend Requests"];
        
        else if (section == kFriendsSuggestions)
            [label setText:@"Friend Suggestions"];
        
        else if (section == kFriendsCurrent)
            [label setText:@"My Friends"];
        
        [view addSubview:label];
        [view setBackgroundColor:SECTION_HEADER_GRAY];
        
        return view;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return CONTACTS_ROW_HEIGHT;
    }
    
    else
    {
        /*if (indexPath.section == kFriendsSuggestions && !self.showFriendSuggestions)
            return CONTACTS_ROW_HEIGHT * 2.0;*/
        
        /*else*/ return CONTACTS_ROW_HEIGHT;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return 0.0f;
    }
    
    else
    {
        return FRIENDS_HEADER_HEIGHT;
    }
}

/*
// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

#pragma mark - UI helper methods

- (UIButton *)createSettingsButton
{
    UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(276.0f, 77.0f, 44.0f, 44.0f)];
    [settingsButton setBackgroundColor:self.mySearchBar.barTintColor];
    
    UIImage *settingsIcon = [Constants renderImage:[UIImage imageNamed:@"glyphicons_136_cogwheel"] inColor:FADED_BLUE];
    settingsIcon = [UIImage imageWithCGImage:settingsIcon.CGImage
                                       scale:1.8f
                                 orientation:UIImageOrientationUp];
    
    [settingsButton setImage:settingsIcon forState:UIControlStateNormal];
    
    return settingsButton;
}

- (UIButton *)createRequestButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(195.0f, 20.0f, 115.0f, 32.0f)];
    
    button.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    button.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f);
    
    [button setTitleShadowColor:TITLE_SHADOW forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateSelected];
    
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    
    [button setBackgroundImage:[UIImage imageNamed:@"buttonRequest.png"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"buttonRequestSelected.png"] forState:UIControlStateSelected];
    
    [button setTitle:@"Accept   " forState:UIControlStateNormal];
    [button setTitle:@"Accept   " forState:UIControlStateSelected];
    
    [button addTarget:self action:@selector(didPressAcceptButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (UIButton *)createSuggestionButton
{
    // add friend button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(195.0f, 20.0f, 115.0f, 32.0f)];
    
    button.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    button.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f);
    
    [button setTitleShadowColor:TITLE_SHADOW forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateSelected];
    
    [button setTitleColor:DARK_BROWN forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    
    [button setBackgroundImage:[UIImage imageNamed:@"buttonAddFriend"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"buttonAddFriendSelected"] forState:UIControlStateSelected];
    
    [button setTitle:@"Add Friend  " forState:UIControlStateNormal];
    [button setTitle:@"Request Sent  " forState:UIControlStateSelected];
    
    [button addTarget:self action:@selector(didPressAddFriendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (UILabel *)createFacebookLabel
{
    UILabel *connectLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 20.0f, 290.0f, 20.0f)];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc] initWithString: @"Find your Facebook friends on LinkMeUp!" attributes: @{ NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: GILL_17}];

    connectLabel.attributedText = labelText;
    
    return connectLabel;
}

- (UIButton *)createFacebookButton
{
    UIButton *linkWithFB = [UIButton buttonWithType:UIButtonTypeCustom];
    [linkWithFB setFrame:CGRectMake(57.0f, 56.0f, 195.0f, 55.0f)]; // centered in cell
    
    [linkWithFB setBackgroundImage:[UIImage imageNamed:@"login-button-small"] forState:UIControlStateNormal];
    [linkWithFB setBackgroundImage:[UIImage imageNamed:@"login-button-small-pressed"] forState:UIControlStateSelected];
    
    linkWithFB.titleLabel.font = HELV_16;
    
    [linkWithFB setTitle:@"            Find Friends" forState:UIControlStateNormal];
    [linkWithFB setTitle:@"            Find Friends" forState:UIControlStateSelected];
    
    [linkWithFB addTarget:self action:@selector(didLinkWithFB:) forControlEvents:UIControlEventTouchUpInside];
    
    return linkWithFB;
}

@end
