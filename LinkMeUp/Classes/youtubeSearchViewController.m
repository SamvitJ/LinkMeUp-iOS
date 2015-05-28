//
//  youtubeSearchViewController.m
//  echoprint
//
//  Created by Samvit Jain on 8/1/14.
//
//

#import "youtubeSearchViewController.h"

#import "searchResultsViewController.h"

@interface youtubeSearchViewController ()

@end

@implementation youtubeSearchViewController


#pragma mark - Data initialization

- (Data *)sharedData
{
    if (!_sharedData)
    {
        echoprintAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
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
    return NO;
}

/*- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
 {
 // Tells the table data source to reload when scope bar selection changes
 [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
 [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
 
 // Return YES to cause the search result table view to be reloaded.
 return NO;
 }*/

#pragma mark - Search bar delegate methods

/*- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
}*/

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    searchResultsViewController *srvc = [[searchResultsViewController alloc] init];
    self.sharedData.userSearchTerm = searchBar.text;
    [self.navigationController pushViewController:srvc animated:NO];
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
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    searchResultsViewController *srvc = [[searchResultsViewController alloc] init];
    self.sharedData.userSearchTerm = [self.searchResults objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:srvc animated:NO];
}

#pragma mark - Autocomplete suggestion requests

- (void)loadSuggestionsForSearchText:(NSString *)searchText
{
    // Autocomplete
    NSLog(@"Start %@", [NSDate date]);
    
    NSString *autocompleteURL = [NSString stringWithFormat:@"http://suggestqueries.google.com/complete/search?hl=en&ds=yt&client=youtube&hjson=t&cp=1&q=%@&key=%@&format=5&alt=json&callback=?", [Constants urlEncodeString:searchText], YOUTUBE_API_KEY];
    NSURLRequest *autocompleteRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:autocompleteURL]];
    
    [NSURLConnection sendAsynchronousRequest:autocompleteRequest queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (!error)
        {
            NSLog(@"Done %@", [NSDate date]);
            
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
            
            NSLog(@"%@", autocompleteSuggestions);
            
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
    
    // initialize search results array
    self.searchResults = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    // reset search bar
    if (self.sharedData.newSong)
    {
        self.searchBar.text = @"";
        self.sharedData.newSong = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
