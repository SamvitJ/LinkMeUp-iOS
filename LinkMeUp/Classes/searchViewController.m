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

// test
#import "pushNotifViewController.h"

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
        if (self.searchBar.isFirstResponder)
        {
            CGPoint tappedPoint = [sender locationInView: self.view];
            UIView *tappedView = [self.view hitTest:tappedPoint withEvent:nil];

            bool isTableView = (tappedView == self.searchDisplayController.searchResultsTableView);
            bool isCellContentView = ([tappedView isMemberOfClass:NSClassFromString(@"UITableViewCellContentView")]);
            bool isButton = ([tappedView isMemberOfClass:[UIButton class]]);
            
            NSLog(@"Tapped view %@", tappedView);
            
            if (!isTableView && !isCellContentView && !isButton)
            {
                [self.searchBar resignFirstResponder];
                
                if (self.currentlyShifted)
                    [self animateScreenContentsInDirection:kDirectionDown];
                
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

#pragma mark - Search display delegate methods

/*-(void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    // NSLog(@"Did load called");
}*/

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    // set frame
    int numberSuggestions = (IS_IPHONE_5 ? 6 : 4);
    CGRect frame = CGRectMake(self.searchBar.frame.origin.x + 8.0f, 6.0f, self.searchBar.frame.size.width - 16.0f, numberSuggestions * AUTOCOMPLETE_ROW_HEIGHT);
    
    tableView.frame = frame;
    
    // remove seperator
    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // NSLog(@"Should reload");
    
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope: [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return NO;
}

#pragma mark - Keyboard notifications

- (void)keyboardWillShow
{
    // NSLog(@"Keyboard will show");
}

- (void)keyboardWillHide
{
    // NSLog(@"Keyboard will hide");
}

#pragma mark - Search bar delegate methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    // NSLog(@"Search bar text should begin editing");
    
    if (!self.currentlyShifted)
        [self animateScreenContentsInDirection:kDirectionUp];
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    // NSLog(@"Search bar text should end editing");
    
    // if search results table is not present
    if (!self.searchDisplayController.isActive && self.currentlyShifted)
        [self animateScreenContentsInDirection:kDirectionDown];
    
    // do not hide keyboard if user is scrolling through table
    /* if (self.searchDisplayController.isActive)
    {
        NSLog(@"Returning no");
        return NO;
    } */
    
    return YES;
}

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
    // NSLog(@"Start autocomplete query");
    
    NSString *autocompleteURL = [NSString stringWithFormat:@"http://suggestqueries.google.com/complete/search?hl=en&ds=yt&client=youtube&hjson=t&cp=1&q=%@&key=%@&format=5&alt=json&callback=?", [Constants urlEncodeString:searchText], YOUTUBE_API_KEY];
    NSURLRequest *autocompleteRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:autocompleteURL]];
    
    // while loading results
    if (![self.searchBar.text isEqualToString:@""] && ![self.searchResults count])
    {
        self.searchResults = [[NSMutableArray alloc] initWithObjects:@"", nil];
        
        // view to hold activity indicator
        self.AIView = [[UIView alloc] initWithFrame: self.searchDisplayController.searchResultsTableView.frame];
        
        // add activity indicator to search results table view
        if (!self.searchDisplayAI)
        {
            self.searchDisplayAI = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.searchDisplayAI.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
            
            CGFloat searchDisplayWidth = self.searchDisplayController.searchResultsTableView.frame.size.width;
            
            CGFloat aiWidth = self.searchDisplayAI.frame.size.width;
            CGFloat aiHeight = self.searchDisplayAI.frame.size.height;
            
            CGFloat horizOffset = 10;
            
            [self.searchDisplayAI setFrame:CGRectMake((searchDisplayWidth - aiWidth)/2 - horizOffset, AUTOCOMPLETE_ROW_HEIGHT + (AUTOCOMPLETE_ROW_HEIGHT - aiHeight)/2, aiWidth, aiHeight)];
            
            [self.AIView addSubview: self.searchDisplayAI];
            self.searchDisplayController.searchResultsTableView.bounces = NO;
        }

        [self.searchDisplayController.searchResultsTableView addSubview: self.AIView];
        [self.searchDisplayAI startAnimating];
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:autocompleteRequest
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error)
        {
            // stop and hide activity indicator
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.searchDisplayAI stopAnimating];
                [self.AIView removeFromSuperview];
                self.searchDisplayController.searchResultsTableView.bounces = YES;
                
            });
            
            // NSLog(@"Done %@", [NSDate date]);
            
            NSArray *myData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            NSString *searchQuery = myData[0];
            NSArray *results = myData[1];
            
            NSLog(@"Query - %@", searchQuery);
            
            NSMutableArray *autocompleteSuggestions = [[NSMutableArray alloc] init];
            for (NSArray *result in results)
            {
                // NSLog(@"%@", result[0]);
                [autocompleteSuggestions addObject:result[0]];
            }
            
            // NSLog(@"%@", autocompleteSuggestions);
            
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
            
        }
    }];
    
    // execute task
    [task resume];
}

#pragma mark - Clear and initialize

- (void)clearAndInitialize
{
    // clear search field
    self.searchBar.text = @"";
    
    // resign first responder
    [self.searchBar resignFirstResponder];
    [self.searchDisplayController setActive:NO animated:NO];
    
    // set status boolean
    self.sharedData.newSong = NO;
}

/* #pragma mark - UI action methods

- (IBAction)sendVideoPressed:(id)sender
{
    // search for video
    [self launchYouTubeSearch];
} */

#pragma mark - View controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // initialize UI
    [self displaySearchIcon];
    [self displaySearchPrompt];
    self.currentlyShifted = NO;
    
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
    self.view.backgroundColor = FAINT_GRAY;
    
    // clear search bar + hide keyboard if new song
    if (self.sharedData.newSong)
        [self clearAndInitialize];
    
    // begin in shifted down state
    if (self.currentlyShifted)
    {
        // NSLog(@"Resetting screen %u", self.currentlyShifted);
        [self resetScreenContents];
    }
    
    // test
    // pushNotifViewController *pnvc = [[pushNotifViewController alloc] init];
    // [self presentViewController:pnvc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - UI helper methods

- (void)displaySearchIcon
{
    if (!self.searchIconView)
    {
        UIImage *searchIcon = [UIImage imageNamed: @"MagnifyingGlass.png"];
        //searchIcon = [Constants renderImage:searchIcon inColor: [UIColor lightGrayColor]];
        
        CGFloat desiredWidth = 85;
        CGFloat desiredHeight = (searchIcon.size.height / searchIcon.size.width) * desiredWidth;
        
        CGFloat viewWidth = self.view.frame.size.width;
        CGFloat viewHeight = self.view.frame.size.height;
        
        CGFloat offsetFromCenterY = (IS_IPHONE_5 ? -20 : -60);
        
        self.searchIconView = [[UIImageView alloc] initWithFrame:CGRectMake((viewWidth - desiredWidth)/2, (viewHeight - desiredHeight)/2 + offsetFromCenterY,
                                                                            desiredWidth, desiredHeight)];
        self.searchIconView.image = searchIcon;
        self.searchIconView.alpha = 0.15;
        
        [self.view addSubview: self.searchIconView];
    }
    
    else
    {
        self.searchIconView.hidden = NO;
    }
}

- (void)displaySearchPrompt
{
    if (!self.captionTitle)
    {
        CGFloat viewWidth = self.view.frame.size.width;
        
        // caption title
        CGFloat titleLength = 200;
        CGFloat titleHeight = 22;
        
        CGFloat searchIconBottomY = self.searchIconView.frame.origin.y + self.searchIconView.frame.size.height;
        CGFloat iconCaptionBuffer = 22.5;
        
        self.captionTitle = [[UILabel alloc] initWithFrame:CGRectMake((viewWidth - titleLength)/2, searchIconBottomY + iconCaptionBuffer, titleLength, titleHeight)];
        self.captionTitle.font = HELV_18;
        self.captionTitle.textColor = [UIColor grayColor];
        
        self.captionTitle.numberOfLines = 1;
        self.captionTitle.textAlignment = NSTextAlignmentCenter;
        
        self.captionTitle.text = [NSString stringWithFormat:@"Search for videos"];
        
        // caption text
        CGFloat textLength = 300;
        CGFloat textHeight = 50;
        
        CGFloat captionTitleBottomY = self.captionTitle.frame.origin.y + self.captionTitle.frame.size.height;
        CGFloat titleTextBuffer = 8;
        
        self.captionText = [[UILabel alloc] initWithFrame:CGRectMake((viewWidth - textLength)/2, captionTitleBottomY + titleTextBuffer, textLength, textHeight)];
    
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 5;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        NSString *captionTextString = [NSString stringWithFormat:@" Find music, comedy, sports, or\n news clips to send to your friends"];
        // NSString *captionTextString = [NSString stringWithFormat:@"Music, comedy, sports, news..."];
        NSMutableAttributedString *captionAttributedText = [[NSMutableAttributedString alloc] initWithString: captionTextString
                                                                                                  attributes: @{NSParagraphStyleAttributeName: paragraphStyle,
                                                                                                                NSFontAttributeName: HELV_15,
                                                                                                                NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
        
        self.captionText.attributedText = captionAttributedText;
        self.captionText.numberOfLines = 2;
        
        // add caption title/text to view
        [self.view addSubview: self.captionTitle];
        [self.view addSubview: self.captionText];
    }
    
    else
    {
        self.captionTitle.hidden = NO;
        self.captionText.hidden = NO;
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

#pragma mark - Search bar animation

- (void)resetScreenContents
{
    float distance = (IS_IPHONE_5 ? 73.5 : 27.5);
    
    // move down (called only if self.currentlyShifted = YES)
    self.searchIconView.frame = CGRectOffset(self.searchIconView.frame, 0.0f, distance);
    self.captionTitle.frame = CGRectOffset(self.captionTitle.frame, 0.0f, distance);
    self.captionText.frame = CGRectOffset(self.captionText.frame, 0.0f, distance);
    
    self.currentlyShifted = NO;
}

- (void)animateScreenContentsInDirection:(Direction)direction
{
    float distance = (IS_IPHONE_5 ? 73.5 : 27.5);
    float movement = ((direction == kDirectionDown) ? distance : -distance);
    float movementDuration = (direction ? 0.15f : 0.3f);
    
    [UIView beginAnimations:@"Scroll" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    
    self.searchIconView.frame = CGRectOffset(self.searchIconView.frame, 0.0f, movement);
    self.captionTitle.frame = CGRectOffset(self.captionTitle.frame, 0.0f, movement);
    self.captionText.frame = CGRectOffset(self.captionText.frame, 0.0f, movement);
    
    [UIView commitAnimations];
    
    self.currentlyShifted = (direction == kDirectionUp ? YES : NO);
}


@end
