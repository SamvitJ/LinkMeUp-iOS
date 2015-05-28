//
//  inboxTableViewController.m
//  echoprint
//
//  Created by Samvit Jain on 6/14/14.
//
//

#import "inboxTableViewController.h"

#import <Parse/Parse.h>

#import "Constants.h"
#import "Link.h"

#import "musicStreamingViewController.h"
#import "echoprintViewController.h"

@interface inboxTableViewController ()

@end

@implementation inboxTableViewController

/*- (void)setMessageArray:(NSMutableArray *)messageArray
{
    _messageArray = messageArray;
}

- (void)setConnectionData:(NSMutableData *)connectionData
{
    _connectionData = connectionData;
}*/

- (IBAction)swipeLeft:(id)sender
{
    // check is previous view controller was echoprintVC
    if ([self.presentingViewController isKindOfClass:[echoprintViewController class]])
        [self dismissViewControllerAnimated:YES completion:nil];
    
    else
    {
        echoprintViewController *newEVC = [[echoprintViewController alloc] init];
        [self presentViewController:newEVC animated:YES completion:nil];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.spinner setCenter:self.tableView.center];
    [self.tableView addSubview:self.spinner];
    [self.spinner startAnimating];*/
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.loaded = [[NSMutableArray alloc] init];
    self.contacts = [[NSMutableArray alloc] init];
    
    __block PFUser *me = [PFUser currentUser];
    
    PFQuery *receivedLinksQuery = [Link query];
    [receivedLinksQuery whereKey:@"receivers" equalTo:me];
    
    PFQuery *sentLinksQuery = [Link query];
    [sentLinksQuery whereKey:@"sender" equalTo:me];
    
    PFQuery *linksQuery = [PFQuery orQueryWithSubqueries:@[receivedLinksQuery, sentLinksQuery]];
    [linksQuery includeKey:@"sender"];
    [linksQuery orderByDescending:@"createdAt"];
    [linksQuery findObjectsInBackgroundWithBlock:^(NSArray *links, NSError *error) {
        if (!error)
        {
            for (int i = 0; i < [links count]; i++)
            {
                self.loaded[i] = @NO;
                PFUser *sender = [links[i] objectForKey:@"sender"];
                
                if (![sender.objectId isEqualToString:me.objectId]) // recieved link
                {
                    NSMutableArray *senders = [[NSMutableArray alloc] init];
                    [senders addObject:sender];
                
                    self.contacts[i] = senders;
                    self.loaded[i] = @YES;
                }
                
                else // I sent it...
                {
                    PFRelation *receivers = [links[i] relationForKey:@"receivers"];
                    
                    NSArray *users = [[receivers query] findObjects];
                    
                    NSMutableArray *recipients = [[NSMutableArray alloc] init];
                    
                    for (PFUser *recipient in users)
                        [recipients addObject:recipient];
                    
                    self.contacts[i] = recipients;
                    self.loaded[i] = @YES;
                    
                    //[self.tableView reloadData];
                    
                    /*[[receivers query] findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
                        if (error)
                        {
                            NSLog(@"Error: %@ %@", error, [error userInfo]);
                            //self.contacts[i] = nil;
                        }
                        
                        else
                        {
                            NSMutableArray *recipients = [[NSMutableArray alloc] init];
                            
                            for (PFUser *recipient in users)
                                [recipients addObject:recipient];
                    
                            [self.contacts insertObject:recipients atIndex:i];
                        }
                        
                        self.loaded[i] = @YES;
                        [self.tableView reloadData];
                    }];*/
                }
            }
            
            //[self.spinner stopAnimating];
            self.links = (NSMutableArray *)links;
            [self.tableView reloadData];
        }
        
        else
        {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (BOOL)canLoadData
{
    for (int i = 0; i < [self.loaded count]; i++)
    {
        if ([self.loaded[i] boolValue] == NO)
             return NO;
    }
    
    return YES;
}

/*
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.connectionData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.connectionData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //NSString *retString = [NSString stringWithUTF8String:[self.connectionData bytes]];
    //NSLog(@"json returned: %@", retString);
    
    NSError *parseError = nil;
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:self.connectionData
                                                         options:0
                                                           error:&parseError];
    
    if (!parseError)
    {
        self.messageArray = jsonArray;
        //NSLog(@"json array is %@", jsonArray);
        [self.tableView reloadData];
    }
    else
    {
        NSString *err = [parseError localizedDescription];
        NSLog(@"Encountered error parsing: %@", err);
    }
    
    connection = nil;
    self.connectionData = nil;
}*/

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Inbox view will appear");
    /*NSURL *msgURL = [NSURL URLWithString:kMessageBoardURLString];
    
    NSURLRequest *msgRequest =
    [NSURLRequest requestWithURL:msgURL
                     cachePolicy:NSURLRequestUseProtocolCachePolicy
                 timeoutInterval:60.0];
    
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:msgRequest delegate:self];
    
    if (theConnection)
    {
        NSMutableData *connData = [[NSMutableData alloc] init];
        [self setConnectionData:connData];
    }
    else
    {
        NSLog(@"Connection failed...");
        //[self.activityView setHidden:YES];
        //[self.activityIndicator stopAnimating];
    }*/
    
    /*PFUser *user = [PFUser currentUser];
    NSString *userId = user.objectId;
    
    PFQuery *query = [PFUser query];
    [query getObjectInBackgroundWithId:userId block:^(PFObject *obj, NSError *error)
     {
         self.parseMessages = [obj objectForKey:@"messages"];
         
         NSLog(@"Most recent song retrieved: %@", [[self.parseMessages lastObject] objectForKey:@"song"]);
         
         [self.tableView reloadData];
     }];*/
    
    //[PFUser logOut];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //return [self.messageArray count];
    return ([self canLoadData] * [self.links count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SongInboxCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.font = GILL_20;
    cell.detailTextLabel.font = GILL_18;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    Link *link = self.links[indexPath.row];
    PFUser *sender = [link objectForKey:@"sender"];
    
    if ([sender.objectId isEqualToString:[PFUser currentUser].objectId]) // I sent it
    {
        cell.backgroundColor = FAINT_BLUE;
        
        NSMutableString *sentTo = [NSMutableString stringWithFormat:@"Sent to... "];
        
        for (PFUser *recipient in self.contacts[indexPath.row])
        {
            NSString *displayName = recipient[@"name"] ? recipient[@"name"] : recipient[@"username"];
            [sentTo appendString:displayName];
            [sentTo appendString:@" "];
        }
        
        cell.textLabel.text = sentTo;
    }
    
    else // someone sent me this link
    {
        if (!link.seen)
        {
            cell.backgroundColor = LIGHT_PURPLE;
        }
        
        else cell.backgroundColor = LIGHT_GRAY;
        
        NSString *displayName = sender[@"name"] ? sender[@"name"] : sender[@"username"];
        cell.textLabel.text = displayName;
    }
    
    cell.detailTextLabel.text = [self.links[indexPath.row] objectForKey:@"songInfo"];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
    
    /*if ([[self.links[indexPath.row] objectForKey:@"sent"] boolValue]) // songs sent
    {
        cell.textLabel.text = [[NSString stringWithFormat:@"Sent to: "] stringByAppendingString:[self.links[indexPath.row] objectForKey:@"contact"]];
        
        cell.backgroundColor = [UIColor colorWithRed:0.8 green:0.95 blue:0.9 alpha:1.0];
    }
    
    else // songs recieved
    {
        cell.textLabel.text = [[NSString stringWithFormat:@"From: "] stringByAppendingString:[self.links[indexPath.row] objectForKey:@"contact"]];
        
        cell.backgroundColor = [UIColor colorWithRed:0.8 green:0.9 blue:0.95 alpha:1.0];
    }
    
    cell.detailTextLabel.text = [self.links[indexPath.row] objectForKey:@"song"];*/
    
    
    
    /*
    cell.textLabel.text = @"Pengy(uin) Jain";
    cell.detailTextLabel.text =  @"ADHD | Kendrick Lamar";
    cell.imageView.image = [UIImage imageNamed:@"Dark_Side_of_the_Moon.png"];
    */
    
    /*
    NSDictionary *message = (NSDictionary *)[[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"message"];
    NSString *byLabel = [NSString stringWithFormat:@"%@ on %@",
                         [message objectForKey:@"name"],
                         [message objectForKey:@"message_date"]];
    
    if ([[message objectForKey:@"name"] isEqualToString:@"Samvit"])
    {
        cell.textLabel.text = byLabel;
        cell.detailTextLabel.text = [message objectForKey:@"message"];
    }
    else
    {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
    }
    */
    

    
    /*UIView *cellBack = [[UIView alloc] initWithFrame:cell.bounds];
    cellBack.backgroundColor = [UIColor lightGrayColor];
    cell.backgroundView = cellBack;*/
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
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    Link *clickedLink = self.links[indexPath.row];
    PFUser *sender = [clickedLink objectForKey:@"sender"];
    
    if (![sender.objectId isEqualToString:[PFUser currentUser].objectId]) // I received it
    {
        clickedLink.seen = YES;
        [clickedLink saveInBackground];

        cell.backgroundColor = LIGHT_GRAY;
    }
    
    musicStreamingViewController *msvc = [[musicStreamingViewController alloc] init];
    
    NSArray *songInfo = [cell.detailTextLabel.text componentsSeparatedByString:@"|"];
    
    if (songInfo[0])
        msvc.songTitle = songInfo[0];
    
    if ([songInfo count] == 2)
        msvc.artist = songInfo[1];
    
    [self presentViewController:msvc animated:YES completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
