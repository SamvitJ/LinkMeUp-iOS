//
//  searchResultsViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 8/1/14.
//
//

#import "searchResultsViewController.h"

#import <MediaPlayer/MediaPlayer.h>

#import "videoTableViewCell.h"

#import "GTLQueryYouTube.h"
#import "GTLServiceYouTube.h"

#import "GTLYouTubeSearchListResponse.h"
#import "GTLYouTubeSearchResult.h"
#import "GTLYouTubeSearchResultSnippet.h"
#import "GTLYouTubeResourceId.h"

#import "GTLYouTubeThumbnailDetails.h"
#import "GTLYouTubeThumbnail.h"

#import "GTLYouTubeVideoListResponse.h"
#import "GTLYouTubeVideo.h"
#import "GTLYouTubeVideoSnippet.h"
#import "GTLYouTubeVideoContentDetails.h"
#import "GTLYouTubeVideoStatistics.h"

@interface searchResultsViewController ()
{
    // loading status
    BOOL queryVEVODone;
    BOOL queryNonVEVODone;
}

@end

@implementation searchResultsViewController


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

#pragma mark - Text view delegate methods

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    sender.cancelsTouchesInView = NO;
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        if (self.annotationView.isFirstResponder)
        {
            [self.annotationView resignFirstResponder];
            sender.cancelsTouchesInView = YES;
        }
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self animateContent:textView inDirection:kDirectionUp];
    
    if ([textView.text isEqualToString:@"Add message"])
    {
        textView.text = @"";
    }
    
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self animateContent:textView inDirection:kDirectionDown];
    
    if ([textView.text isEqualToString:@""])
    {
        textView.text = @"Add message";
    }
    
    [textView resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    
    if ([textView.text length] + text.length > ANNOTATION_CHAR_LIMIT)
    {
        return NO;
    }
    
    return YES;
}

#pragma mark - UI action methods

- (void)playButtonPressed:(id)sender
{
    UIButton *playButton = sender;
    NSLog(@"Play button pressed %u", (int)playButton.tag);
    
    playButton.enabled = NO;
    [self displayActivityIndicatorForCell: (int)playButton.tag];
    [self loadWebViewForCell:(int)playButton.tag autoplay:YES];
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendToPressed:(id)sender
{
    if (!self.contactsVC)
        self.contactsVC = [[contactsViewController alloc] init];
    
    // set contacts VC state
    self.contactsVC.isForwarding = NO;
    
    // set new song data
    self.sharedData.isSong = NO;
    
    self.sharedData.youtubeVideoId = [self.videos[self.selectedCell] objectForKey:@"videoId"];
    self.sharedData.youtubeVideoTitle = [self.videos[self.selectedCell] objectForKey:@"videoTitle"];
    self.sharedData.youtubeVideoChannel = [self.videos[self.selectedCell] objectForKey:@"videoChannel"];
    self.sharedData.youtubeVideoViews = [self.videos[self.selectedCell] objectForKey:@"videoViews"];
    self.sharedData.youtubeVideoDuration = [self.videos[self.selectedCell] objectForKey:@"videoDuration"];
    self.sharedData.youtubeVideoThumbnail = [self.videos[self.selectedCell] objectForKey:@"videoHQThumbnail"];
    
    self.sharedData.annotation = ([self.annotationView.text isEqualToString:@"Add message"] ? @"" : self.annotationView.text);

    // push contactsVC
    [self.navigationController pushViewController:self.contactsVC animated:YES];
}

#pragma mark - Web view delegate

- (UIButton *)findButtonInView:(UIView *)view
{
    UIButton *button = nil;
    
    if ([view isMemberOfClass:[UIButton class]])
    {
        NSLog(@"Found button");
        return (UIButton *)view;
    }
    
    if (view.subviews && [view.subviews count] > 0)
    {
        NSLog(@"View %@", view);
        for (UIView *subview in view.subviews)
        {
            NSLog(@"Subview: %@", subview);
            
            button = [self findButtonInView:subview];
            
            if (button)
            {
                NSLog(@"Found button");
                return button;
            }
        }
        NSLog(@"\n\n\n");
    }
    
    return button;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Error loading webview %@", error);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // log status
    /*(webView.isLoading ? NSLog(@"Webview %u still loading", (int)webView.tag) : NSLog(@"Webview %u did finish load", (int)webView.tag));*/
    
    // enable autoplay
    webView.mediaPlaybackRequiresUserAction = NO;
    
    // adjust webview
    [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.zoom = 0.65;"];
    
    NSString *contentSizeScript = @"var meta = document.createElement('meta'); "
    "meta.setAttribute( 'name', 'viewport' ); "
    "meta.setAttribute( 'content', 'width = 180' ); "
    "document.getElementsByTagName('head')[0].appendChild(meta)";
    
    [webView stringByEvaluatingJavaScriptFromString: contentSizeScript];

    // stop activity indicator
    UIActivityIndicatorView *activityIndicator = self.activityIndicators[webView.tag];
    [activityIndicator stopAnimating];
    
    // display web view
    webView.hidden = NO;
    
    // reload cells
    [self.tableView reloadData];
}

#pragma mark - Youtube query

- (void)launchSearchListQueryForSearchTerm:(NSString *)searchTerm
{
    NSLog(@"Search list query begun...");
    GTLServiceYouTube *youtubeService = [[GTLServiceYouTube alloc] init];
    youtubeService.APIKey = YOUTUBE_API_KEY;
    
    
    
    // VEVO video query
    GTLQueryYouTube *videoQueryVEVO = [GTLQueryYouTube queryForSearchListWithPart:@"id,snippet"];
    
    videoQueryVEVO.maxResults = 8;
    videoQueryVEVO.q = searchTerm;
    videoQueryVEVO.type = @"video";
    
    [youtubeService executeQuery:videoQueryVEVO
               completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        if (!error)
        {
            GTLYouTubeSearchListResponse *searchResults = object;
            
            for (int i = 0; i < [searchResults.items count]; i++)
            {
                GTLYouTubeSearchResult *result = searchResults.items[i];
                GTLYouTubeResourceId *identifier = result.identifier;
                GTLYouTubeSearchResultSnippet *snippet = result.snippet;
                
                //NSString *videoTitle = [snippet.JSON objectForKey:@"title"];
                NSString *videoId = [identifier.JSON objectForKey:@"videoId"];
                NSString *videoChannel = [snippet.JSON objectForKey:@"channelTitle"];
                
                // if channel title contains string 'VEVO', add video
                if ([videoChannel rangeOfString:@"VEVO"].location != NSNotFound)
                {
                    NSMutableDictionary *videoData = [[NSMutableDictionary alloc] init];
                
                    //if (videoTitle) videoData[@"videoTitle"] = videoTitle;
                    if (videoId) videoData[@"videoId"] = videoId;
                    
                    if (!self.VEVOvideos)
                        self.VEVOvideos = [[NSMutableArray alloc] initWithObjects:videoData, nil];
                    
                    else [self.VEVOvideos addObject:videoData];
                }
            }
            
            queryVEVODone = YES;
            [self launchStatsQuery];
        }
    }];
    
    
    
    // video query
    GTLQueryYouTube *videoQuery = [GTLQueryYouTube queryForSearchListWithPart:@"id,snippet"];
    
    videoQuery.videoSyndicated = @"true";
    
    videoQuery.maxResults = 10;
    videoQuery.q = searchTerm;
    videoQuery.type = @"video";
    
    [youtubeService executeQuery:videoQuery
               completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        if (!error)
        {
            NSLog(@"Found videos!");
            GTLYouTubeSearchListResponse *searchResults = object;
            
            
            for (int i = 0; i < [searchResults.items count]; i++)
            {
                GTLYouTubeSearchResult *result = searchResults.items[i];
                GTLYouTubeResourceId *identifier = result.identifier;
                //GTLYouTubeSearchResultSnippet *snippet = result.snippet;
                
                //NSString *videoTitle = [snippet.JSON objectForKey:@"title"];
                NSString *videoId = [identifier.JSON objectForKey:@"videoId"];
                
                NSMutableDictionary *videoData = [[NSMutableDictionary alloc] init];
                
                //if (videoTitle) videoData[@"videoTitle"] = videoTitle;
                if (videoId) videoData[@"videoId"] = videoId;
                
                [self.videos addObject:videoData];
            }
        
            queryNonVEVODone = YES;
            [self launchStatsQuery];
        }
                   
        else
        {
            NSLog(@"Error executing search list query %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)launchStatsQuery
{
    if (!queryVEVODone || !queryNonVEVODone)
        return;
    
    // if VEVO video found
    if (self.VEVOvideos)
    {
        // merge arrays without duplicates
        NSMutableOrderedSet *allVideos = [[NSMutableOrderedSet alloc] initWithArray:self.VEVOvideos];
        [allVideos addObjectsFromArray:self.videos];
        
        self.videos = [[allVideos array] mutableCopy];
    }
    
    // initialize content arrays
    self.imageViews = [[NSMutableArray alloc] init];
    self.activityIndicators = [[NSMutableArray alloc] init];
    self.webViews = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.videos count]; i++)
    {
        self.imageViews[i] = [[UIImageView alloc] init];
        self.activityIndicators[i] = [[UIActivityIndicatorView alloc] init];
        self.webViews[i] = [[UIWebView alloc] init];
    }
    
    // build videoId list
    NSMutableString *videoIdList = [[NSMutableString alloc] init];
    for (int i = 0; i < [self.videos count]; i++)
    {
        // add videoId to videoId list
        [videoIdList appendString:[[self.videos objectAtIndex:i] objectForKey:@"videoId"]];
        [videoIdList appendString:@","];
    }
    
    NSLog(@"Stats query begun...");
    GTLServiceYouTube *youtubeService = [[GTLServiceYouTube alloc] init];
    youtubeService.APIKey = YOUTUBE_API_KEY;
    
    GTLQueryYouTube *statsQuery = [GTLQueryYouTube queryForVideosListWithPart:@"id,snippet,contentDetails,statistics"];
    statsQuery.identifier = videoIdList;
    
    [youtubeService executeQuery:statsQuery
               completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        
        if (!error)
        {
            NSLog(@"Found stats!");
            GTLYouTubeVideoListResponse *videoResults = object;
            

            for (int i = 0; i < [videoResults.items count]; i++)
            {
                GTLYouTubeVideo *video = videoResults.items[i];
                GTLYouTubeVideoSnippet *videoSnippet = video.snippet;
                GTLYouTubeVideoContentDetails *videoDetails = video.contentDetails;
                GTLYouTubeVideoStatistics *videoStatistics = video.statistics;
                
                NSString *videoTitle = [videoSnippet.JSON objectForKey:@"title"];
                NSString *videoChannel = [videoSnippet.JSON objectForKey:@"channelTitle"];
                NSNumber *videoDuration = [Constants ISO8601FormatToFloatSeconds:[videoDetails.JSON objectForKey:@"duration"]];
                NSNumber *videoViews = [[[NSNumberFormatter alloc] init] numberFromString:[videoStatistics.JSON objectForKey:@"viewCount"]];
            
                NSDictionary *thumbnails = [videoSnippet.JSON objectForKey:@"thumbnails"];
                NSDictionary *defaultThumbnail = [thumbnails objectForKey:@"defaultProperty"];
                NSDictionary *hqThumbnail = [thumbnails objectForKey:@"high"];
                
                NSString *videoDefaultThumbnail = [defaultThumbnail objectForKey:@"url"];
                NSString *videoHQThumbnail = [hqThumbnail objectForKey:@"url"];
                
                /*NSString *videoTitle = videoSnippet.title;
                NSString *videoChannel = videoSnippet.channelTitle;
                NSNumber *videoDuration = [Constants ISO8601FormatToFloatSeconds:videoDetails.duration];
                NSNumber *videoViews = videoStatistics.viewCount;
                
                // video thumbnails
                GTLYouTubeThumbnailDetails *thumbnails = videoSnippet.thumbnails;
                GTLYouTubeThumbnail *defaultThumbnail = thumbnails.defaultProperty;
                GTLYouTubeThumbnail *hqThumbnail = thumbnails.high;
                
                NSString *videoDefaultThumbnail = defaultThumbnail.url;
                NSString *videoHQThumbnail = hqThumbnail.url;*/
                
                // set video fields
                NSMutableDictionary *videoData = self.videos[i];
                if (videoTitle) videoData[@"videoTitle"] = videoTitle;
                if (videoChannel) videoData[@"videoChannel"] = videoChannel;
                if (videoViews) videoData[@"videoViews"] = videoViews;
                if (videoDuration) videoData[@"videoDuration"] = videoDuration;
                if (videoDefaultThumbnail) videoData[@"videoDefaultThumbnail"] = videoDefaultThumbnail;
                if (videoHQThumbnail) videoData[@"videoHQThumbnail"] = videoHQThumbnail;
        
                // NSLog(@"\nVideo %u \n%@ \n%@ \n%@ \n%@ \n%@ \n%@\n\n", i, videoTitle, videoData[@"videoId"], videoChannel, videoViews, videoDuration, video);
                
                // load thumbnail for video
                [self loadThumbnailForCell:i];
                //[self loadWebViewForCell:i];
            }
            
            // allow user interaction
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.mainActivityIndicator stopAnimating];
            });
            
            [self.tableView reloadData];
            self.tableView.hidden = NO;
            
            [self displayAnnotationView];
        }
        
        else
        {
            NSLog(@"Error executing video list query %@ %@", error, [error userInfo]);
        }
    }];
}

#pragma mark - Load thumbnail image

- (void)loadThumbnailForCell:(int)index
{
    NSString *thumbnailURL = [self.videos[index] objectForKey:@"videoHQThumbnail"];
    
    dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(aQueue, ^{
        
        // get thumbnail from URL
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:thumbnailURL]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // UIImage from data
            UIImage *thumbnail = [UIImage imageWithData: imageData];
                                  
            // add image to image view
            UIImageView *imageView = [[UIImageView alloc] initWithFrame: CGRectMake(10.0f, 10.0f, 180.0f, 135.0f)];
            imageView.tag = index;
            
            [imageView setImage:thumbnail];
            
            // play icon
            UIImage *playIcon = [UIImage imageNamed:@"glyphicons_173_play"];
            playIcon = [UIImage imageWithCGImage:[playIcon CGImage]
                                           scale:(playIcon.scale * 1.2)
                                     orientation:UIImageOrientationUp];
            playIcon = [Constants renderImage:playIcon inColor:[UIColor redColor]];
            
            // play button
            UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectMake((imageView.frame.size.width - playIcon.size.width)/2.0f + 6.0f, (imageView.frame.size.height - playIcon.size.height)/2.0f, playIcon.size.width, playIcon.size.height)];
            playButton.tag = index;
            
            [playButton setImage:playIcon forState:UIControlStateNormal];
            [playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            // add play button to image view
            imageView.userInteractionEnabled = YES;
            [imageView addSubview:playButton];
            
            self.imageViews[index] = imageView;
            [self.tableView reloadData];
        });
    });
}

#pragma mark - Display activity indicator

- (void)displayActivityIndicatorForCell:(int)index
{
    UIImageView *imageView = self.imageViews[index];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityIndicator.tag = index;
    activityIndicator.center = CGPointMake(imageView.bounds.size.width/2.0f, imageView.bounds.size.height/2.0f);
    
    [activityIndicator startAnimating];
    
    self.activityIndicators[index] = activityIndicator;
    [imageView addSubview: self.activityIndicators[index]];
}

#pragma mark - Load video request

- (void)loadWebViewForCell:(int)index autoplay:(BOOL)shouldAutoplay
{
    UIWebView *youtubeWebView = [[UIWebView alloc] initWithFrame: CGRectMake(10.0f, 10.0f, 180.0f, 135.0f)];
    
    youtubeWebView.tag = index;
    youtubeWebView.delegate = self;
    youtubeWebView.scrollView.scrollEnabled = NO;
    
    // allow autoplay
    youtubeWebView.mediaPlaybackRequiresUserAction = NO;
    youtubeWebView.mediaPlaybackAllowsAirPlay = YES;
    
    // Load request in UIWebView
    NSString *URL = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@%@", [self.videos[index] objectForKey:@"videoId"], (shouldAutoplay ? @"&autoplay=1" : @"")];
    [youtubeWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URL]]];
    
    // Add webview to array
    self.webViews[index] = youtubeWebView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.videos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Video Results";
    
    videoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[videoTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.transform = CGAffineTransformRotate(CGAffineTransformIdentity, k90DegreesClockwiseAngle);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.backgroundColor = [UIColor whiteColor]; // FAINT_GRAY;
    }
    
    // remove all subviews that should now be off screen
    // NSLog(@"Cell %u...now removing subviews", indexPath.row);
    NSArray *indexPaths = [tableView indexPathsForVisibleRows];
    for (int i = 0; i < [self.videos count]; i++)
    {
        if (![indexPaths containsObject:[NSIndexPath indexPathForRow:i inSection:0]])
        {
            //NSLog(@"%u cell not visible", i);
            [self.imageViews[i] removeFromSuperview];
            [self.webViews[i] removeFromSuperview];
        }
    }
    
    // load imageview
    [cell addSubview:self.imageViews[indexPath.row]];
    
    // load webview
    [cell addSubview:self.webViews[indexPath.row]];
    
    // cell labels
    cell.titleLabel.text = [self.videos[indexPath.row] objectForKey:@"videoTitle"];
    cell.channelLabel.text = [self.videos[indexPath.row] objectForKey:@"videoChannel"];
    cell.viewsLabel.text = [[NSNumberFormatter localizedStringFromNumber:[self.videos[indexPath.row] objectForKey:@"videoViews"] numberStyle:NSNumberFormatterDecimalStyle] stringByAppendingString:@" views"];
    
    if (self.selectedCell == indexPath.row)
    {
        cell.layer.borderColor = BRIGHT_GREEN.CGColor;
        cell.layer.borderWidth = 2.0f;
    }
    
    else
    {
        cell.layer.borderColor = [UIColor clearColor].CGColor;
        cell.layer.borderWidth = 0.0f;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // deselect currently selected cell
    NSIndexPath *path = [NSIndexPath indexPathForRow:self.selectedCell inSection:0];
    UITableViewCell *previousSelection = [tableView cellForRowAtIndexPath:path];
    
    previousSelection.layer.borderColor = [UIColor clearColor].CGColor;
    previousSelection.layer.borderWidth = 0.0f;
    
    if (self.selectedCell != indexPath.row) // change selected cell
    {
        self.selectedCell = (int)indexPath.row;
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        
        selectedCell.layer.borderColor = BRIGHT_GREEN.CGColor;
        selectedCell.layer.borderWidth = 2.0f;
        
        [Constants enableButton:self.sendToButton];
    }
    
    else // no cell selected
    {
        self.selectedCell = -1;
        
        [Constants disableButton:self.sendToButton];
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
    
    // begin query
    [self launchSearchListQueryForSearchTerm:self.sharedData.userSearchTerm];
    
    // set table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.hidden = YES;
    
    // initialize
    self.videos = [[NSMutableArray alloc] init];
    self.selectedCell = -1;
    
    // exit text fields gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    // disable send button
    [Constants disableButton:self.sendToButton];
    
    // add back button
    UIButton *backButton = [Constants createBackButtonWithText:@"Search"];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:backButton];
    
    // start activity indicator
    self.mainActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.mainActivityIndicator.center = CGPointMake(self.view.frame.size.width / 2.0, 170.0f + (IS_IPHONE5 ? 30.0f : 0.0f));
    self.mainActivityIndicator.transform = CGAffineTransformMakeScale(1.6f, 1.6f);
    [self.mainActivityIndicator startAnimating];
    [self.view addSubview: self.mainActivityIndicator];
    
    // use screen space
    if (IS_IPHONE5)
        self.tableView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0f, 50.0f);
    
    // rotate table
    [self.tableView setAutoresizingMask:UIViewAutoresizingNone];
    self.tableView.transform = CGAffineTransformRotate(self.tableView.transform, k90DegreesCounterClockwiseAngle);
    
    /*// alternate solution: autolayout constraints
    UIView *header = self.header;
    UITableView *table = self.tableView;
    UIButton *button = self.sendToButton;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(header, table, button);
    NSDictionary *metrics = @{@"header_height":[NSNumber numberWithFloat:self.header.frame.size.height],
                              @"table_height":[NSNumber numberWithFloat:self.tableView.frame.size.height],
                              @"button_height":[NSNumber numberWithFloat:self.sendToButton.frame.size.height]};
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[header(header_height)]-[table(table_height)]-[button(button_height)-49-|]" options:0 metrics:metrics views:viewsDictionary];
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[table]|" options:0 metrics:nil views:viewsDictionary];
    self.header.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.sendToButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:verticalConstraints];
    [self.view addConstraints:horizontalConstraints];*/
}

- (void)viewWillAppear:(BOOL)animated
{
    self.view.backgroundColor = [UIColor whiteColor]; // FAINT_GRAY;
    self.tableView.backgroundColor = [UIColor whiteColor]; // FAINT_GRAY;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"Search Results VC received memory warning");
    
    // handle memory warning
    for (int i = 0; i < [self.videos count]; i++)
    {
        if (i != self.selectedCell)
        {
            // set webview strong pointers to nil
            UIWebView *webView = self.webViews[i];
            [webView stopLoading];
            webView.delegate = nil;
            self.webViews[i] = [[UIWebView alloc] init];
            
            // (re)enable play button
            UIImageView *imageView = self.imageViews[i];
            for (UIView *view in imageView.subviews)
            {
                if ([view isKindOfClass:[UIButton class]])
                {
                    //NSLog(@"Found play button for image view %u", i);
                    UIButton *playButton = (UIButton *)view;
                    playButton.enabled = YES;
                }
            }
        }
    }
}

- (void)dealloc
{
    NSLog(@"Now deallocating");

    // stop loading webview content
    // set webview delegates to nil
    for (int i = 0; i < [self.videos count]; i++)
    {
        UIWebView *webView = self.webViews[i];
        [webView stopLoading];
        webView.delegate = nil;
    }
}

#pragma mark - UI helper methods

- (void)displayAnnotationView
{
    // annotation text view
    self.annotationView = [[UITextView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 300.0f)/2, self.tableView.frame.origin.y + self.tableView.frame.size.height + 10.0f + (IS_IPHONE5 ? 10.0f : 0.0f), 300.0f, 47.0f)];
    self.annotationView.backgroundColor = [UIColor clearColor];
    
    self.annotationView.scrollEnabled = NO;
    self.annotationView.textAlignment = NSTextAlignmentCenter;
    self.annotationView.textColor = HYPERLINK_BLUE;
    self.annotationView.font = HELV_16;
    self.annotationView.text = @"Add message";
    
    self.annotationView.delegate = self;
    
    [self.view addSubview:self.annotationView];
}

#pragma mark - Text view animation

- (void)animateContent:(UITextView *)textView inDirection:(Direction)direction
{
    float distance = 108.0f;
    float movement = (direction ? distance : -distance);
    float movementDuration = 0.3f;
    
    [UIView beginAnimations:@"Scroll" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];

    //self.tableView.center = CGPointMake(self.tableView.center.x, self.tableView.center.y + movement);
    //self.tableView.transform = CGAffineTransformTranslate(self.tableView.transform, 0.0f, movement);
    
    if (IS_IOS8)
        self.tableView.bounds = CGRectOffset(self.tableView.bounds, movement, 0.0f);
    else
        self.tableView.frame = CGRectOffset(self.tableView.frame, 0.0f, movement);
        
    self.annotationView.frame = CGRectOffset(self.annotationView.frame, 0.0f, movement);
    
    [UIView commitAnimations];
}

@end
