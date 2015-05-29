//
//  friendsTableViewController.m
//  echoprint
//
//  Created by Samvit Jain on 6/27/14.
//
//

#import "friendsTableViewController.h"

#import <Parse/Parse.h>

#import "Constants.h"
#import "FriendRequest.h"

#define REQUESTS 0
#define FRIENDS 1
#define SUGGESTIONS 2

@interface friendsTableViewController ()

@end

@implementation friendsTableViewController

- (IBAction)swipeRight:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    NSLog(@"Reached view did load");
    
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.suggestionButtons = [[NSMutableArray alloc] init];
    self.requestButtons = [[NSMutableArray alloc] init];

    self.requestSenders = [[NSMutableArray alloc] init];
    self.friendsSuggested = [[NSMutableArray alloc] init];
    self.myFriends = [[NSMutableArray alloc] init];
    
    self.loadedRequests = NO;
    self.loadedSuggestions = NO;
    self.loadedFriends = NO;
    
    // if not linked already, link to FB account
    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
    {
        [PFFacebookUtils linkUser:[PFUser currentUser]
                      permissions:@[ @"public_profile", @"user_friends", @"email"]
                            block:^(BOOL succeeded, NSError *error) {
                                if (succeeded)
                                {
                                    // get the user's data from Facebook
                                    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *fbUser, NSError *error)
                                     {
                                         PFUser *me = [PFUser currentUser];
                                         me[@"facebook_id"] = fbUser.objectID;
                                         me[@"name"] = [[fbUser.first_name stringByAppendingString:@" "] stringByAppendingString:fbUser.last_name];
                                         [me saveInBackground];
                                     }];
                                    
                                    NSLog(@"Linked your facebook account!");
                                }
                                else
                                {
                                    NSLog(@"Error Msg: %@", [error localizedDescription]);
                                }
                            }];
    }
    
    [self loadData];
}

- (void)loadData
{
    // check for received friend requests
    PFQuery *newRequestsQuery = [FriendRequest query];
    [newRequestsQuery whereKey:@"receiver" equalTo:[PFUser currentUser]];
    [newRequestsQuery whereKey:@"accepted" equalTo:@NO];
    [newRequestsQuery orderByDescending:@"createdAt"];
    [newRequestsQuery includeKey:@"sender"];
    [newRequestsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error)
        {
            // The find succeeded.
            NSLog(@"Successfully retrieved %d friend requests.", (int)objects.count);
            
            self.friendRequests = (NSMutableArray *)objects;
            
            // Do something with the found objects
            for (int i = 0; i < [self.friendRequests count]; i++)
            {
                FriendRequest *request = self.friendRequests[i];
                PFUser *sender = request.sender;
                
                self.requestSenders[i] = sender;
                NSLog(@"Sender name: %@", self.requestSenders[i][@"name"]);
            }
            
            self.loadedRequests = YES;
            [self loadFriendSuggestions];
            [self.tableView reloadData];
        }
        
        else
        {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    
    // load friends
    __block PFUser *me = [PFUser currentUser];
    
    PFQuery *newFriendsQuery = [FriendRequest query];
    [newFriendsQuery whereKey:@"sender" equalTo:me];
    [newFriendsQuery whereKey:@"accepted" equalTo:@YES];
    [newFriendsQuery orderByDescending:@"createdAt"];
    [newFriendsQuery includeKey:@"receiver"];
    [newFriendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error)
        {
            for (FriendRequest *request in objects)
            {
                PFRelation *myFriends = [me relationForKey:@"friends"];
                [myFriends addObject:request.receiver];
                [request deleteInBackground];
            }
            
            [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                PFRelation *myFriends = [me relationForKey:@"friends"];
                [[myFriends query] findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (error)
                    {
                        // Log details of the failure
                        NSLog(@"Error: %@ %@", error, [error userInfo]);
                    }
                    
                    else
                    {
                        // objects has all the Posts the current user liked.
                        NSLog(@"I have %d friends", (int)[objects count]);
                        self.myFriends = (NSMutableArray *)objects;
                        
                        self.loadedFriends = YES;
                        [self loadFriendSuggestions];
                        [self.tableView reloadData];
                    }
                }];
            }];
        }
        
        else
        {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            
            self.myFriends = me[@"friends"];
            
            self.loadedFriends = YES;
            [self loadFriendSuggestions];
            [self.tableView reloadData];
        }
    }];
    
}

- (void)loadFriendSuggestions
{
    if (self.loadedRequests && self.loadedFriends)
    {
        // friend suggestions
        FBRequest* friendSuggestions = [FBRequest requestForMyFriends];
        [friendSuggestions startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                         NSDictionary* result,
                                                         NSError *error)
         {
             self.FBFriendSuggestions = (NSMutableArray *)[result objectForKey:@"data"];
             
             // generate array of fbIDs
             NSMutableArray *fbIDs = [[NSMutableArray alloc] init];
             for (int i = 0; i < [self.FBFriendSuggestions count]; i++)
             {
                 NSDictionary<FBGraphUser>* FBfriend = self.FBFriendSuggestions[i];
                 fbIDs[i] = FBfriend.objectID;
                 NSLog(@"FB Friends: %@", fbIDs[i]);
             }
             
             // generate array of friendIDs
             NSMutableArray *friendIDs = [[NSMutableArray alloc] init];
             for (int i = 0; i < [self.myFriends count]; i++)
             {
                 PFUser *myFriend = self.myFriends[i];
                 friendIDs[i] = myFriend.objectId;
                 NSLog(@"Friends: %@", friendIDs[i]);
             }
             
             // generate array of requestIDs
             NSMutableArray *requestIDs = [[NSMutableArray alloc] init];
             for (int i = 0; i < [self.requestSenders count]; i++)
             {
                 PFUser *potentialFriend = self.requestSenders[i];
                 requestIDs[i] = potentialFriend.objectId;
                 NSLog(@"Requests: %@", requestIDs[i]);
             }
             
             NSArray *excludedIDs = [friendIDs arrayByAddingObjectsFromArray:requestIDs];
             
             PFQuery *query = [PFUser query];
             [query whereKey:@"facebook_id" containedIn:fbIDs];
             [query whereKey:@"objectId" notContainedIn:excludedIDs];
             [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                 if (!error)
                 {
                     self.friendsSuggested = (NSMutableArray *)objects;
                     
                     for (PFUser *suggestedFriend in self.friendsSuggested)
                     {
                         NSLog(@"Suggestion: %@", suggestedFriend[@"name"]);
                     }
                 }
                 
                 else
                 {
                     // Log details of the failure
                     NSLog(@"Error: %@ %@", error, [error userInfo]);
                 }
                 
                 self.loadedSuggestions = YES;
                 [self.tableView reloadData];
             }];
         }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"Reached tableView: numberOfRowsInSection:");
        
    if (section == REQUESTS)
        return [self.requestSenders count];
    
    else if (section == FRIENDS)
        return [self.myFriends count];
    
    else if (section == SUGGESTIONS)
        return [self.friendsSuggested count];
    
    else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Reached tableView: cellForRowAtIndexPath:");
    
    static NSString *CellIdentifier;
    if (indexPath.section == REQUESTS)
    {
        CellIdentifier = @"Friend Requests";
    }
    else if (indexPath.section == FRIENDS)
    {
        CellIdentifier = @"Friends";
    }
    else if (indexPath.section == SUGGESTIONS)
    {
        CellIdentifier = @"Suggestions";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.font = GILL_20;
    
    if (indexPath.section == REQUESTS)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = indexPath.row;
        
        [button setFrame:CGRectMake(195.0f, 20.0f, 115.0f, 32.0f)];
        
        button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f);
        
        [button setTitleShadowColor:TITLE_SHADOW
                           forState:UIControlStateNormal];
        [button setTitleShadowColor:[UIColor blackColor]
                           forState:UIControlStateSelected];
        
        button.titleLabel.shadowOffset = CGSizeMake( 0.0f, -1.0f);
        
        NSLog(@"Requests: %d %d", (int)indexPath.section, (int)indexPath.row);
        
        PFUser *displayPerson = self.requestSenders[indexPath.row];
        cell.textLabel.text = (displayPerson[@"name"] ? displayPerson[@"name"] : displayPerson[@"username"]);
        
        cell.backgroundColor = LIGHT_PURPLE;
        
        button.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        [button setBackgroundImage:[UIImage imageNamed:@"buttonRequest.png"] forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:@"buttonRequestSelected.png"] forState:UIControlStateSelected];
        
        [button setTitle:@"Accept   " forState:UIControlStateNormal];
        [button setTitle:@"Accept   " forState:UIControlStateSelected];
        
        [button addTarget:self action:@selector(didPressAcceptButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        self.requestButtons[indexPath.row] = button;
        [cell.contentView addSubview: self.requestButtons[indexPath.row]];
    }
    
    else if (indexPath.section == FRIENDS)
    {
        NSLog(@"Friends: %d %d", (int)indexPath.section, (int)indexPath.row);
        
        PFUser *displayPerson = self.myFriends[indexPath.row];
        cell.textLabel.text = (displayPerson[@"name"] ? displayPerson[@"name"] : displayPerson[@"username"]);

        cell.backgroundColor = LIGHT_BLUE;
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    else if (indexPath.section == SUGGESTIONS)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = indexPath.row;
        
        [button setFrame:CGRectMake(195.0f, 20.0f, 115.0f, 32.0f)];
        
        button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f);
        
        [button setTitleShadowColor:TITLE_SHADOW
                           forState:UIControlStateNormal];
        [button setTitleShadowColor:[UIColor blackColor]
                           forState:UIControlStateSelected];
        
        button.titleLabel.shadowOffset = CGSizeMake( 0.0f, -1.0f);
        
        NSLog(@"Suggestions: %d %d %@", (int)indexPath.section, (int)indexPath.row, ((PFUser *)self.friendsSuggested[indexPath.row])[@"name"]);
        
        PFUser *displayPerson = self.friendsSuggested[indexPath.row];
        cell.textLabel.text = (displayPerson[@"name"] ? displayPerson[@"name"] : displayPerson[@"username"]);
        
        cell.backgroundColor = LIGHT_GREEN;
        
        button.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        
        [button setTitleColor:DARK_BROWN
                     forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor]
                     forState:UIControlStateSelected];
        
        [button setBackgroundImage:[UIImage imageNamed:@"buttonAddFriend"] forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:@"buttonAddFriendSelected"] forState:UIControlStateSelected];
        
        [button setTitle:@"Add Friend  " forState:UIControlStateNormal];
        [button setTitle:@"Request Sent  " forState:UIControlStateSelected];
        
        [button addTarget:self action:@selector(didPressFriendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        self.suggestionButtons[indexPath.row] = button;
        [cell.contentView addSubview: self.suggestionButtons[indexPath.row]];
    }
    
    return cell;
}

// accept pressed
- (void)didPressAcceptButtonAction:(id)sender
{
    UIButton *clicked = (UIButton *)sender;
    int index = (int)clicked.tag;
    
    if (!clicked.selected)
    {
        clicked.selected = YES;
        
        FriendRequest *request = self.friendRequests[index];
        request.accepted = YES;
        [request saveInBackground];
        
        PFUser *user = [PFUser currentUser];
        NSString *userId = user.objectId;
        
        PFQuery *query = [PFUser query];
        [query getObjectInBackgroundWithId:userId block:^(PFObject *obj, NSError *error)
         {
             PFUser *me = (PFUser *)obj;
             PFRelation *myFriends = [me relationForKey:@"friends"];
             
             [myFriends addObject:self.requestSenders[index]];
             
             [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                 if (succeeded)
                 {
                     [self.myFriends addObject:self.requestSenders[index]];
                     [self.requestSenders removeObjectAtIndex:index];
                     [self.tableView reloadData];
                     
                     //[self loadData];
                 }
                 
                 else
                 {
                     // Log details of the failure
                     NSLog(@"Error: %@ %@", error, [error userInfo]);
                 }
             }];
         }];
    }
}

// add friend/cancel request pressed
- (void)didPressFriendButtonAction:(id)sender
{
    UIButton *clicked = (UIButton *)sender;
    int index = (int)clicked.tag;
    
    if (!clicked.selected)
    {
        clicked.selected = YES;
        
        PFUser *receiver = self.friendsSuggested[index];

        FriendRequest *request = [[FriendRequest alloc] init];
        request.sender = [PFUser currentUser];
        request.accepted = NO;
        request.receiver = receiver;
        
        PFACL *pairACL = [PFACL ACL];
        
        [pairACL setReadAccess:YES forUser:[PFUser currentUser]];
        [pairACL setWriteAccess:YES forUser:[PFUser currentUser]];
        [pairACL setReadAccess:YES forUser:receiver];
        [pairACL setWriteAccess:YES forUser:receiver];
        
        request.ACL = pairACL;
        [request saveInBackground];
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
    UIView *view = [[UIView alloc] init];//initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 500)];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 20)];
    
    [label setFont:[UIFont boldSystemFontOfSize:16]];
    
    if (section == REQUESTS)
        [label setText:@"Friend Requests"];
    
    else if (section == FRIENDS)
        [label setText:@"My Friends"];
    
    else if (section == SUGGESTIONS)
        [label setText:@"Friend Suggestions"];

    [view addSubview:label];
    [view setBackgroundColor:SECTION_HEADER_GRAY]; //your background color...
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CONTACT_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SECTION_HEADER_HEIGHT;
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

@end
