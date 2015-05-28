//
//  searchViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 8/4/14.
//
//

#import "searchViewController.h"

#import "songInfoViewController.h"
#import "searchResultsViewController.h"

@interface searchViewController ()

@end

@implementation searchViewController


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

#pragma mark - Exit gesture

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    sender.cancelsTouchesInView = NO;
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        if (self.titleField.isFirstResponder)
        {
            [self.titleField resignFirstResponder];
            sender.cancelsTouchesInView = YES;
        }
        
        else if (self.artistField.isFirstResponder)
        {
            [self.artistField resignFirstResponder];
            sender.cancelsTouchesInView = YES;
        }
        
        else if (self.searchBar.isFirstResponder)
        {
            // if user clicks outside search results table view...
            if (!(sender.view == self.searchDisplayController.searchResultsTableView))
            {
                [self.searchBar resignFirstResponder];
                
                // to prevent UISearchBar text reset
                NSString *searchText = self.searchDisplayController.searchBar.text;
                [self.searchDisplayController setActive:NO animated:NO];
                self.searchDisplayController.searchBar.text = searchText;
                
                // to prevent undesirable UI behavior
                self.searchDisplayController.searchResultsTableView.hidden = YES;
            }
        }
    }
}

#pragma mark - Text field delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.titleField || textField == self.artistField)
    {
        if ([self.titleField.text isEqualToString:@""] && [self.artistField.text isEqualToString:@""])
        {
            return NO;
        }
        
        else
        {
            songInfoViewController *svc = [[songInfoViewController alloc] init];
            svc.backgroundColor = BLUE_200;
            
            self.sharedData.userTitle = self.titleField.text;
            self.sharedData.userArtist = self.artistField.text;
            
            [self.navigationController pushViewController:svc animated:NO];
            
            return NO;
        }
    }
    
    return NO;
}

#pragma mark - Search display delegate methods

/*-(void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    NSLog(@"Did load called");
}*/

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    CGRect frame = CGRectMake(self.searchBar.frame.origin.x + 8.0f, -5.0f, self.searchBar.frame.size.width - 16.0f, (IS_IPHONE5 ? 5 : 3)*AUTOCOMPLETE_ROW_HEIGHT);
    
    // set frame
    tableView.frame = frame;
    
    // remove seperator
    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope: [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return NO;
}

#pragma mark - Search bar delegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self launchYouTubeSearch];
    
    // to prevent UISearchBar text reset
    NSString *searchText = self.searchDisplayController.searchBar.text;
    [self.searchDisplayController setActive:NO animated:NO];
    self.searchDisplayController.searchBar.text = searchText;
    
    // to prevent undesirable UI behavior
    self.searchDisplayController.searchResultsTableView.hidden = YES;
}

#pragma mark - Search filtering

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
    [self loadSuggestionsForSearchText:searchText];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Autocomplete suggestions";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [self.searchResults objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return AUTOCOMPLETE_ROW_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // show selected autocomplete suggestion in search bar
    self.searchBar.text = [self.searchResults objectAtIndex:indexPath.row];
    
    // launch search results VC after 0.3 second delay
    [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(launchYouTubeSearch) userInfo:nil repeats:NO];
}

#pragma mark - Launch search results VC

- (void)launchYouTubeSearch
{
    searchResultsViewController *srvc = [[searchResultsViewController alloc] initWithNibName:(IS_IOS8 ? @"searchResultsViewControlleriOS8" : @"searchResultsViewController") bundle:nil];
        
    self.sharedData.userSearchTerm = self.searchBar.text;
    
    [self.navigationController pushViewController:srvc animated:NO];
    
    // to prevent undesirable UI behavior
    self.searchDisplayController.searchResultsTableView.hidden = YES;
}

#pragma mark - Autocomplete suggestion requests

- (void)loadSuggestionsForSearchText:(NSString *)searchText
{
    // Autocomplete
    //NSLog(@"Start autocomplete query");
    
    NSString *autocompleteURL = [NSString stringWithFormat:@"http://suggestqueries.google.com/complete/search?hl=en&ds=yt&client=youtube&hjson=t&cp=1&q=%@&key=%@&format=5&alt=json&callback=?", [Constants urlEncodeString:searchText], YOUTUBE_API_KEY];
    NSURLRequest *autocompleteRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:autocompleteURL]];
    
    [NSURLConnection sendAsynchronousRequest:autocompleteRequest queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (!error)
        {
            //NSLog(@"Done %@", [NSDate date]);
            
            NSArray *myData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            NSString *searchQuery = myData[0];
            NSArray *results = myData[1];
            
            NSLog(@"%@", searchQuery);
            
            NSMutableArray *autocompleteSuggestions = [[NSMutableArray alloc] init];
            for (NSArray *result in results)
            {
                //NSLog(@"%@", result[0]);
                [autocompleteSuggestions addObject:result[0]];
            }
            
            //NSLog(@"%@", autocompleteSuggestions);
            
            // if current text is equal to search query text...
            if ([self.searchBar.text isEqualToString:searchText])
            {
                // Reload search results
                self.searchResults = autocompleteSuggestions;
                
                [self.searchDisplayController.searchResultsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            }
        }
        
        else
        {
            NSLog(@"Error loading autocomplete suggestions %@", error);
        }
    }];
}

#pragma mark - Clear and initialize

- (void)clearAndInitialize
{
    // clear search fields
    self.titleField.text = @"";
    self.artistField.text = @"";
    self.searchBar.text = @"";
    
    // resign first responder
    [self.titleField resignFirstResponder];
    [self.artistField resignFirstResponder];
    [self.searchBar resignFirstResponder];
    [self.searchDisplayController setActive:NO animated:NO];
    
    // default state: send song
    [self setDefaultState];
    
    // set status boolean
    self.sharedData.newSong = NO;
}

#pragma mark - Default state

- (void)setDefaultState
{
    // default setting
    self.selectedState = kSendSong;
    
    [Constants highlightButton:self.sendSongButton];
    [Constants fadeButton:self.sendVideoButton];
    
    [self displaySongPrompt];
    [self displayTitleField];
    [self displayArtistField];
    
    self.videoPromptLabel.hidden = YES;
    self.searchBar.hidden = YES;
}

#pragma mark - UI action methods

- (IBAction)sendVideoPressed:(id)sender
{
    if (self.selectedState == kSendSong)
    {
        // toggle state
        self.selectedState = kSendVideo;
        
        [Constants highlightButton:self.sendVideoButton];
        [Constants fadeButton:self.sendSongButton];
        
        [self displayVideoPrompt];
        self.searchBar.hidden = NO;
        //[self displayVideoSearchBar];
        
        self.songPromptLabel.hidden = YES;
        self.titleField.hidden = YES;
        self.artistField.hidden = YES;
        
        // make search bar first responder
        //[self.searchBar becomeFirstResponder];
    }
    
    else
    {
        // search for video
        [self launchYouTubeSearch];
    }
}

- (IBAction)sendAudioPressed:(id)sender
{
    if (self.selectedState == kSendVideo)
    {
        // toggle state
        [self setDefaultState];
    }
    
    else
    {
        // if both fields are not null, search for song
        if (!([self.titleField.text isEqualToString:@""] && [self.artistField.text isEqualToString:@""]))
        {
            songInfoViewController *svc = [[songInfoViewController alloc] init];
            svc.backgroundColor = BLUE_200;
            
            self.sharedData.userTitle = self.titleField.text;
            self.sharedData.userArtist = self.artistField.text;
            
            [self.navigationController pushViewController:svc animated:NO];
        }
    }
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
    
    // default setting: send song
    [self setDefaultState];
    
    // exit gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    // set view background
    self.view.backgroundColor = BLUE_200;
    
    if (self.sharedData.newSong)
        [self clearAndInitialize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI helper methods

- (void)displaySongPrompt
{
    if (!self.songPromptLabel)
    {
        self.songPromptLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 103.0f, 290.0f, 25.0f)];
        self.songPromptLabel.font = HELV_18;
        self.songPromptLabel.textColor = [UIColor whiteColor];
        self.songPromptLabel.text = @"Enter song info   ";
        
        [self.view addSubview:self.songPromptLabel];
    }
    
    else
    {
        self.songPromptLabel.hidden = NO;
    }
}

- (void)displayTitleField
{
    if (!self.titleField)
    {
        self.titleField = [[UITextField alloc] initWithFrame:CGRectMake(15.0f, 130.0f, 290.0f, 40.0f)];
        self.titleField.delegate = self;
        
        self.titleField.borderStyle = UITextBorderStyleRoundedRect;
        self.titleField.backgroundColor = [UIColor whiteColor];
        
        self.titleField.font = HELV_16;
        self.titleField.placeholder = @"Title";
        self.titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        self.titleField.returnKeyType = UIReturnKeySearch;
        
        [self.view addSubview:self.titleField];
    }
    
    else
    {
        self.titleField.hidden = NO;
    }
}

- (void)displayArtistField
{
    if (!self.artistField)
    {
        self.artistField = [[UITextField alloc] initWithFrame:CGRectMake(15.0f, 170.0f, 290.0f, 40.0f)];
        
        self.artistField.delegate = self;
        
        self.artistField.borderStyle = UITextBorderStyleRoundedRect;
        self.artistField.backgroundColor = [UIColor whiteColor];
        
        self.artistField.font = HELV_16;
        self.artistField.placeholder = @"Artist";
        self.artistField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        self.artistField.returnKeyType = UIReturnKeySearch;
        
        [self.view addSubview:self.artistField];
    }
    
    else
    {
        self.artistField.hidden = NO;
    }
}

- (void)displayVideoPrompt
{
    if (!self.videoPromptLabel)
    {
        self.videoPromptLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 103.0f, 290.0f, 25.0f)];
        self.videoPromptLabel.font = HELV_18;
        self.videoPromptLabel.textColor = [UIColor whiteColor];
        self.videoPromptLabel.text = @"Music, comedy, sports, news...";
        
        [self.view addSubview:self.videoPromptLabel];
    }
    
    else
    {
        self.videoPromptLabel.hidden = NO;
    }
}

/*- (void)displayVideoSearchBar
{
    if (!self.searchBar)
    {
        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(15.0f, 130.0f, 290.0f, 30.0f)];
        self.searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
        
        self.searchBar.translucent = NO;
        self.searchBar.backgroundColor = [UIColor whiteColor];
        self.searchBar.placeholder = @"Search for video";
        
        // search bar/search display controller delegates
        self.searchBar.delegate = self;
        self.searchDisplay.delegate = self;
        self.searchDisplay.searchResultsDelegate = self;
        self.searchDisplay.searchResultsDataSource = self;
        
        // initialize search results array
        self.searchResults = [[NSMutableArray alloc] init];
    }
    
    else
    {
        self.searchBar.hidden = NO;
    }
}*/

@end
