//
//  linkViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/22/14.
//
//

#import "linkViewController.h"

#import "Constants.h"
#import "messagesTableViewCell.h"

#import "songInfoViewController.h"

#import "GTLQueryYouTube.h"
#import "GTLServiceYouTube.h"

#import "GTLYouTubeSearchListResponse.h"
#import "GTLYouTubeSearchResult.h"
#import "GTLYouTubeSearchResultSnippet.h"
#import "GTLYouTubeResourceId.h"

#import "GTLYouTubeVideoListResponse.h"
#import "GTLYouTubeVideo.h"
#import "GTLYouTubeVideoSnippet.h"
#import "GTLYouTubeVideoContentDetails.h"
#import "GTLYouTubeVideoStatistics.h"

@interface linkViewController ()
{
    // query status
    BOOL queryVEVODone;
    BOOL queryNonVEVODone;
    
    // webview loading status
    BOOL loadedRequest;
    
    // search term
    NSString *searchTerm;
    
    // video Ids for best results
    NSString *bestVEVO;
    NSString *bestNonVEVO;
}

@end

@implementation linkViewController


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

#pragma mark - Toolbar methods

- (void)forwardButtonPressed:(id)sender
{
    // set fields
    songInfoViewController *srvc = [[songInfoViewController alloc] init];
    srvc.isForwarding = YES;
    
    self.sharedData.isSong = self.sharedData.selectedLink.isSong;
    
    // forwarding song
    if (self.sharedData.selectedLink.isSong)
    {
        self.sharedData.iTunesTitle = self.sharedData.selectedLink.title;
        self.sharedData.iTunesArtist = self.sharedData.selectedLink.artist;
        self.sharedData.iTunesAlbum = self.sharedData.selectedLink.album;
        self.sharedData.iTunesArt = self.sharedData.selectedLink.art;
        self.sharedData.iTunesDuration = self.sharedData.selectedLink.duration;
        self.sharedData.iTunesURL = self.sharedData.selectedLink.storeURL;
        self.sharedData.iTunesPreviewURL = self.sharedData.selectedLink.previewURL;
    }
    
    // forwarding video
    else
    {
        self.sharedData.youtubeVideoId = self.sharedData.selectedLink.videoId;
        self.sharedData.youtubeVideoTitle = self.sharedData.selectedLink.title;
        self.sharedData.youtubeVideoThumbnail = self.sharedData.selectedLink.art;
        self.sharedData.youtubeVideoChannel = self.sharedData.selectedLink.videoChannel;
        self.sharedData.youtubeVideoViews = self.sharedData.selectedLink.videoViews;
        self.sharedData.youtubeVideoDuration = self.sharedData.selectedLink.videoDuration;
    }
    
    // push song info VC
    [self.navigationController pushViewController:srvc animated:YES];
}

- (void)iTunesLinkPressed:(id)sender
{
    NSString *iTunesURL = self.sharedData.selectedLink.storeURL;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesURL]];
}

- (void)iTunesPreviewButtonPressed:(id)sender
{
    if (!self.previewButton.selected) // if showing play button
    {
        if (!self.songPlayer) // no song player
        {
            // play from start
            
            // initialize AVPlayer
            NSURL *previewURL = [NSURL URLWithString:self.sharedData.selectedLink.previewURL];
            self.songPlayer = [[AVPlayer alloc] initWithURL:previewURL];
            
            // add self as observer to AVPlayer "did play to end" notification
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.songPlayer currentItem]];
            
            // add self as observer to AVPlayer field "status"
            [self.songPlayer addObserver:self forKeyPath:@"status" options:0 context:nil];
            
            // display activity indicator
            self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.loadingIndicator.center = CGPointMake(10.0f, 12.0f);
            [self.loadingIndicator startAnimating];
            
            [self.previewButton addSubview:self.loadingIndicator];
        }
        
        else // track paused
        {
            // if track has loaded
            if (self.songPlayer.status == AVPlayerStatusReadyToPlay)
            {
                // resume play
                self.previewButton.selected = YES;
                [self.songPlayer play];
            }
        }
    }
    
    else // showing pause button (currently playing)
    {
        // pause track
        self.previewButton.selected = NO;
        [self.songPlayer pause];
    }
}

#pragma mark - AVPlayer notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.songPlayer && [keyPath isEqualToString:@"status"])
    {
        if (self.songPlayer.status == AVPlayerStatusFailed)
        {
            NSLog(@"AVPlayer Failed");
        }
        
        else if (self.songPlayer.status == AVPlayerStatusReadyToPlay)
        {
            NSLog(@"AVPlayer ReadyToPlay");
            self.previewButton.selected = YES;
            
            [self.loadingIndicator stopAnimating];
            [self.songPlayer play];
        }
        
        else if (self.songPlayer.status == AVPlayerItemStatusUnknown)
        {
            NSLog(@"AVPlayer Unknown");
        }
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    // remove self as observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    // remove self as observer
    [self.songPlayer removeObserver:self forKeyPath:@"status"];
    
    // show play button and deallocate AVPlayer
    self.previewButton.selected = NO;
    self.songPlayer = nil;
}

#pragma mark - Scroll view and web view delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.contentSize.height);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // adjust webview
    [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.zoom = 0.65;"];
        
    NSString* js = @"var meta = document.createElement('meta'); "
    "meta.setAttribute( 'name', 'viewport' ); "
    "meta.setAttribute( 'content', 'width = 320' ); "
    "document.getElementsByTagName('head')[0].appendChild(meta)";
        
    [webView stringByEvaluatingJavaScriptFromString: js];
    
    // show webview
    [self.activityIndicator stopAnimating];
    self.webView.hidden = NO;
    
    loadedRequest = YES;
    [self.tableView reloadData];
}

#pragma mark - Swipe gestures

- (IBAction)swipeRight:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UI action methods

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

// Youtube video cell
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

// Youtube video cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    
    if (indexPath.section == kLinkYoutube)
    {
        CellIdentifier = @"Link - Youtube";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        // add webview if not already added to cell
        if (![cell viewWithTag:@"Web View"])
        {
            self.webView.hidden = YES;
            [cell addSubview: self.webView];
        }
        
        // add iTunes material if not already added to cell
        if (self.sharedData.selectedLink.isSong)
        {
            if (loadedRequest)
            {
                if (![cell viewWithTag:@"iTunes Preview"])
                {
                    self.previewButton = [self createiTunesPreviewButton];
                    self.previewButton.tag = @"iTunes Preview";
                    
                    [cell addSubview:self.previewButton];
                }
                
                if (![cell viewWithTag:@"iTunes Link"])
                {
                    UILabel *iTunesLabel = [self createiTunesLabel];
                    iTunesLabel.tag = @"iTunes Link";
                    
                    [cell addSubview:iTunesLabel];
                }
            }
        }
        
        return cell;
    }
    
    else // (section == kLinkMessages)
    {
        return nil; // left to subclasses to implement
    }
}

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.sharedData.selectedLink.isSong && section == kLinkYoutube)
    {
        UIView *view = [[UIView alloc] init];
        UILabel *label = [self createSongInfoHeaderLabel];
        
        [view addSubview:label];
        [view setBackgroundColor:SECTION_HEADER_GRAY];
        
        return view;
    }
    
    else return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.sharedData.selectedLink.isSong && section == kLinkYoutube)
    {
        return SONG_HEADER_HEIGHT;
    }
    
    else return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kLinkYoutube)
    {
        if (self.sharedData.selectedLink.isSong)
            return YOUTUBE_LINK_ROW_HEIGHT + ITUNES_INFO_HEIGHT;
            
        else
            return YOUTUBE_LINK_ROW_HEIGHT;
    }
    
    else // (section == kLinkMessages)
    {
        return MESSAGES_ROW_HEIGHT;
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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // initialize table
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // initialize web view
    loadedRequest = NO;
    self.webView = [[UIWebView alloc] init];
    
    // if link is song, launch VEVO and nonVEVO YT search result queries
    if (self.sharedData.selectedLink.isSong)
    {
        NSLog(@"Loading song...");
        [self launchYouTubeAPIQueries];
    }
    
    else // otherwise load sent video
    {
        NSLog(@"Loading video...");
        [self loadVideoWithId:self.sharedData.selectedLink.videoId];
    }
    
    // add back button
    UIButton *backButton = [Constants createBackButtonWithText:@"Inbox"];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:backButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    // activity indicator
    NSIndexPath *pathForLinkCell = [NSIndexPath indexPathForRow:0 inSection:kLinkYoutube];
    UITableViewCell *linkCell = [self.tableView cellForRowAtIndexPath:pathForLinkCell];
    
    if (!loadedRequest)
    {
        // initialize and start animating
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicator.transform = CGAffineTransformMakeScale(1.6f, 1.6f);
        self.activityIndicator.center = CGPointMake(linkCell.bounds.size.width / 2.0, 75.0f);
        [self.activityIndicator startAnimating];
        [linkCell addSubview: self.activityIndicator];
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    // set tableview delegates to nil
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    
    // remove self as observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    // remove self as observer
    [self.songPlayer removeObserver:self forKeyPath:@"status"];
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

#pragma mark - YouTube requests

- (void)loadVideoWithId:(NSString *)videoId
{
    // embedded playing
    // NSDictionary *playerVars = @{@"playsinline" : @1,};
    // [self.playerView loadWithVideoId:videoId]; //playerVars:playerVars];
    // [self.playerView playVideo];
    
    // load request
    NSString *URL = [[NSString stringWithFormat:@"https://www.youtube.com/watch?v="] stringByAppendingString:videoId];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    
    // create web view
    self.webView.frame = CGRectMake(0.0f, 0.0f, 320.0f, 190.0f);
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.delegate = self;
    self.webView.tag = @"Web View";
    
    // load webview request
    [self.webView loadRequest: request];
}

- (void)setVideoId
{
    if (queryVEVODone && queryNonVEVODone)
    {
        // choose VEVO or nonVEVO (if VEVO is null)
        NSString *videoId = (bestVEVO ? bestVEVO : bestNonVEVO);
        
        [self loadVideoWithId:videoId];
    }
}

- (void)launchYouTubeAPIQueries
{
    // YouTube queries
    queryNonVEVODone = NO;
    queryVEVODone = NO;
    
    searchTerm = [[self.sharedData.selectedLink.title stringByAppendingString:@" "] stringByAppendingString:self.sharedData.selectedLink.artist];
    
    GTLServiceYouTube *youtubeService = [[GTLServiceYouTube alloc] init];
    youtubeService.APIKey = YOUTUBE_API_KEY;
    
    
    
    // VEVO video query
    GTLQueryYouTube *videoQueryVEVO = [GTLQueryYouTube queryForSearchListWithPart:@"id,snippet"];
    
    videoQueryVEVO.maxResults = 3;
    videoQueryVEVO.q = searchTerm;
    videoQueryVEVO.type = @"video";
    
    [youtubeService executeQuery:videoQueryVEVO
               completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        if (!error)
        {
            GTLYouTubeSearchListResponse *searchResults = object;
            
            //NSLog(@"VEVO Query Results **************************\n\n");
            for (int i = 0; i < [searchResults.items count]; i++)
            {
                GTLYouTubeSearchResult *result = searchResults.items[i];
                GTLYouTubeResourceId *identifier = result.identifier;
                GTLYouTubeSearchResultSnippet *snippet = result.snippet;
                
                //NSString *videoTitle = snippet.title;
                NSString *videoId = [identifier.JSON objectForKey:@"videoId"];
                NSString *videoChannel = [snippet.JSON objectForKey:@"channelTitle"];
                
                //NSLog(@"Title: %@", videoTitle);
                //NSLog(@"Video Id: %@", videoId);
                //NSLog(@"Channel: %@\n\n", videoChannel);
                
                // if channel title contains string 'VEVO', select video
                if ([videoChannel rangeOfString:@"VEVO"].location != NSNotFound)
                {
                    bestVEVO = videoId;
                    break;
                }
            }
            
            queryVEVODone = YES;
            [self setVideoId];
        }
        
        else
        {
            NSLog(@"Error making VEVO query %@ %@", error, [error userInfo]);
        }
    }];
    
    
    
    // best non-VEVO video
    NSMutableString *identifierList = [[NSMutableString alloc] init];
    GTLQueryYouTube *videoQueryNonVEVO = [GTLQueryYouTube queryForSearchListWithPart:@"id,snippet"];
    
    videoQueryNonVEVO.videoSyndicated = @"true";
    //videoQuery.videoEmbeddable = @"true";
    
    videoQueryNonVEVO.maxResults = 10;
    videoQueryNonVEVO.q = searchTerm;
    videoQueryNonVEVO.type = @"video";
    
    [youtubeService executeQuery:videoQueryNonVEVO completionHandler:^(GTLServiceTicket *ticket,
                                                                       id object, NSError *error) {
        if (!error)
        {
            GTLYouTubeSearchListResponse *searchResults = object;
            
            //NSLog(@"Regular Query Results ***********************\n\n");
            
            for (int i = 0; i < [searchResults.items count]; i++)
            {
                GTLYouTubeSearchResult *result = searchResults.items[i];
                GTLYouTubeResourceId *identifier = result.identifier;
                
                // add videoId to identifier list
                [identifierList appendString:[identifier.JSON objectForKey:@"videoId"]];
                [identifierList appendString:@","];
            }
            
            // query for video stats
            GTLQueryYouTube *statsQuery = [GTLQueryYouTube queryForVideosListWithPart:@"id,snippet,contentDetails,statistics"];
            statsQuery.identifier = identifierList;
            
            [youtubeService executeQuery:statsQuery
                       completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                if (!error)
                {
                    GTLYouTubeVideoListResponse *videoResults = object;
                    NSMutableArray *videoScores = [[NSMutableArray alloc] init];
                    
                    for (int i = 0; i < [videoResults.items count]; i++)
                    {
                        GTLYouTubeVideo *video = videoResults.items[i];
                        GTLYouTubeVideoSnippet *videoSnippet = video.snippet;
                        GTLYouTubeVideoContentDetails *videoDetails = video.contentDetails;
                        GTLYouTubeVideoStatistics *videoStatistics = video.statistics;
                        
                        // video parameters
                        NSString *videoId = video.identifier;
                        NSString *videoTitle = [videoSnippet.JSON objectForKey:@"title"];
                        //NSString *videoChannel = [videoSnippet.JSON objectForKey:@"channel"];
                        NSNumber *videoDuration = [Constants ISO8601FormatToFloatSeconds:[videoDetails.JSON objectForKey:@"duration"]];
                        NSNumber *videoViews = [[[NSNumberFormatter alloc] init] numberFromString:[videoStatistics.JSON objectForKey:@"viewCount"]];
                        
                        /* // video parameters
                        NSString *videoId = video.identifier;
                        NSString *videoTitle = videoSnippet.title;
                        //NSString *videoChannel = videoSnippet.channelTitle;
                        NSNumber *videoDuration = [Constants ISO8601FormatToFloatSeconds:videoDetails.duration];
                        NSNumber *videoViews = videoStatistics.viewCount; */
                        
                        // score video
                        float currentVideoScore = 100.0f;
                        currentVideoScore += [self truncatedLengthScoreForTitle:videoTitle];
                        currentVideoScore += [self bannedKeywordScoreForTitle:videoTitle];
                        currentVideoScore += [self favoredKeywordScoreForTitle:videoTitle];
                        currentVideoScore += [self scoreForRank:i];
                        currentVideoScore += [self scoreForViews:[videoViews intValue]];
                        currentVideoScore += [self scoreForDuration:[videoDuration floatValue]];
                        
                        videoScores[i] = [[NSMutableDictionary alloc] init];
                        videoScores[i][@"videoId"] = videoId;
                        videoScores[i][@"score"] = [NSNumber numberWithFloat:currentVideoScore];
                        
                        //NSLog(@"\n Title: %@\n Channel: %@\n Id: %@\n Duration: %@\n Views: %@\n Score: %f\n\n", videoTitle, videoChannel, videoId, videoDetails.duration, videoViews, currentVideoScore);
                    }
                    
                    // determine highest scoring video
                    int bestVideoIndex = 0;
                    float bestVideoScore = [[videoScores[0] objectForKey:@"score"] floatValue];
                    
                    for (int i = 0; i < [videoScores count]; i++)
                    {
                        float currentVideoScore = [[videoScores[i] objectForKey:@"score"] floatValue];
                        
                        if (currentVideoScore > bestVideoScore)
                        {
                            bestVideoIndex = i;
                            bestVideoScore = currentVideoScore;
                        }
                    }
                    
                    // found winner
                    bestNonVEVO = [videoScores[bestVideoIndex] objectForKey:@"videoId"];
                    //NSLog(@"Winning video: %@", self.bestNonVEVO);
                    
                    queryNonVEVODone = YES;
                    [self setVideoId];
                }
                
                else
                {
                    NSLog(@"Error making stats query %@ %@", error, [error userInfo]);
                }
            }];
        }
        
        else
        {
            NSLog(@"Error making non-VEVO query %@ %@", error, [error userInfo]);
        }
        
    }];
}

#pragma mark - Search result scoring methods

- (float)scoreForDuration:(float)resultDuration
{
    float score;
    
    if (fabsf(resultDuration - [self.sharedData.selectedLink.duration floatValue]) <= 3.0f)
        score = 30.0f;
    
    else if (fabsf(resultDuration - [self.sharedData.selectedLink.duration floatValue])/[self.sharedData.selectedLink.duration floatValue] <= 0.03f)
        score = 15.0f;
    
    else
        score = 0.0f;
    
    //NSLog(@"Duration score: %f", score);
    return score;
}

- (float)scoreForViews:(int)resultViews
{
    float score;
    
    if (resultViews <= 1000) // 1,000
    {
        score = 0.0f;
    }
    
    else if (resultViews <= 100000) // 100,000
    {
        //   1,000 -> 0
        //  10,000 -> 5
        // 100,000 -> 10
        
        score = 5.0f * log10f(1.0f * resultViews) - 15.0f;
    }
    
    else if (resultViews <= 100000000) // 100,000,000
    {
        //     100,000 -> 10
        //   1,000,000 -> 20
        //  10,000,000 -> 30
        // 100,000,000 -> 40
        
        score = 10.0f * log10f(1.0f * resultViews) - 40.0f;
    }
    
    else // > 100,000,000
    {
        score = 40.0f;
    }
    
    //NSLog(@"Views score: %f", score);
    return score;
}

- (float)scoreForRank:(int)resultRank
{
    float score = -2.0f * resultRank;
    
    //NSLog(@"Rank score: %f", score);
    return score;
}

- (float)favoredKeywordScoreForTitle:(NSString *)resultTitle
{
    float score;
    
    if ([resultTitle rangeOfString:@"Official Music Video" options:NSCaseInsensitiveSearch].location != NSNotFound)
        score = 30.0f;
    
    else if ([resultTitle rangeOfString:@"Official Video" options:NSCaseInsensitiveSearch].location != NSNotFound)
        score = 30.0f;
    
    else if ([resultTitle rangeOfString:@"Official" options:NSCaseInsensitiveSearch].location != NSNotFound)
        score = 15.0f;
    
    else score = 0.0f;
    
    //NSLog(@"Favored keywords score: %f", score);
    return score;
}

- (float)bannedKeywordScoreForTitle:(NSString *)resultTitle
{
    float score;
    
    NSString *songDescription = [[searchTerm stringByAppendingString:@" "] stringByAppendingString:self.sharedData.selectedLink.album];
    
    // banned keywords in original song title/album/artist
    BOOL isInstrumental = [songDescription rangeOfString:@"Instrumental" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isCover = [songDescription rangeOfString:@"Cover" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isTutorial = [songDescription rangeOfString:@"Tutorial" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isParody = [songDescription rangeOfString:@"Parody" options:NSCaseInsensitiveSearch].location != NSNotFound;
    
    BOOL isRemix = [songDescription rangeOfString:@"Remix" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isMix = [songDescription rangeOfString:@"Mix" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isRemake = [songDescription rangeOfString:@"Remake" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isScrewed = [songDescription rangeOfString:@"Screwed" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isChopped = [songDescription rangeOfString:@"Chopped" options:NSCaseInsensitiveSearch].location != NSNotFound;
    
    BOOL isLive = [songDescription rangeOfString:@"Live" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isSlowed = [songDescription rangeOfString:@"Slowed" options:NSCaseInsensitiveSearch].location != NSNotFound;
    
    // banned keywords in search result title
    BOOL isResultInstrumental = [resultTitle rangeOfString:@"Instrumental" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isResultCover = [resultTitle rangeOfString:@"Cover" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isResultTutorial = [resultTitle rangeOfString:@"Tutorial" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isResultParody = [resultTitle rangeOfString:@"Parody" options:NSCaseInsensitiveSearch].location != NSNotFound;
    
    BOOL isResultRemix = [resultTitle rangeOfString:@"Remix" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isResultMix = [resultTitle rangeOfString:@"Mix" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isResultRemake = [resultTitle rangeOfString:@"Remake" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isResultScrewed = [resultTitle rangeOfString:@"Screwed" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isResultChopped = [resultTitle rangeOfString:@"Chopped" options:NSCaseInsensitiveSearch].location != NSNotFound;
    
    BOOL isResultLive = [resultTitle rangeOfString:@"Live" options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL isResultSlowed = [resultTitle rangeOfString:@"Slowed" options:NSCaseInsensitiveSearch].location != NSNotFound;
    
    if ((!isInstrumental && isResultInstrumental) || (!isCover && isResultCover)  || (!isTutorial && isResultTutorial) || (!isParody && isResultParody))
        score = -60.0f;
    
    else if ((!isRemix && isResultRemix) || (!isMix && isResultMix) ||(!isRemake && isResultRemake) || (!isScrewed && isResultScrewed) || (!isChopped && isResultChopped))
        score = -45.0f;
    
    else if ((!isLive && isResultLive) || (!isSlowed && isResultSlowed))
        score = -30.0f;
    
    else
        score = 0.0f;
    
    //NSLog(@"Banned keywords score: %f", score);
    return score;
}

- (float)truncatedLengthScoreForTitle:(NSString *)resultTitle
{
    float score;
    
    NSString *truncatedTitle = [self truncatedTitleForString:resultTitle];
    
    score = -1.0f * (float)(truncatedTitle.length/2.0);
    
    //NSLog(@"Truncated title: %@", truncatedTitle);
    //NSLog(@"Truncated title length: %i", (int)truncatedTitle.length);
    //NSLog(@"Truncated title score: %f", score);
    
    return score;
}

- (NSString *)truncatedTitleForString:(NSString *)original
{
    // positive keywords
    NSString *title = [[self.sharedData.selectedLink.title componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@""];
    NSString *artist = [[self.sharedData.selectedLink.artist componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@""];
    NSString *album = [[self.sharedData.selectedLink.album componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@""];
    NSArray *otherWords = @[/*@"lyrics", @"lyric", */@"official", @"original"];
    NSArray *allKeywords = [[NSArray arrayWithObjects:title, artist, album, nil] arrayByAddingObjectsFromArray:otherWords];
    
    NSString *truncatedTitle = [[original componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@""];
    
    for (NSString *keyword in allKeywords)
    {
        truncatedTitle = [truncatedTitle stringByReplacingOccurrencesOfString:keyword
                                                                   withString:@""
                                                                      options:NSCaseInsensitiveSearch
                                                                        range:NSMakeRange(0, truncatedTitle.length)];
    }
    
    return truncatedTitle;
}

#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    NSLog(@"Reached");
    
    //UILabel *iTunesLabel = (UILabel *)gestureRecognizer.view;
    //iTunesLabel.highlighted = YES;
    
    return YES;
}

#pragma mark - UI helper methods

- (UILabel *)createSongInfoHeaderLabel
{
    // title and subtitle
    NSString *title = self.sharedData.selectedLink.title;
    NSString *subtitle = [NSString stringWithFormat:@"%@ | %@", self.sharedData.selectedLink.artist, self.sharedData.selectedLink.album];
    
    // truncate title and subtitle
    if ([title length] > 35)
    {
        title = [title substringToIndex: MIN([title length] - 3, 35)];
        title = [title stringByAppendingString:@"..."];
    }
    
    if ([subtitle length] > 45)
    {
        subtitle = [subtitle substringToIndex: MIN([subtitle length] - 3, 45)];
        subtitle = [subtitle stringByAppendingString:@"..."];
    }
    
    // set label text
    NSString *labelText = [NSString stringWithFormat:@"%@\n%@", title, subtitle];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.lineSpacing = 4.0;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 7.0f, self.tableView.frame.size.width - 20.0f, SONG_HEADER_HEIGHT - 10.0f)];
    label.numberOfLines = 2;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSMutableAttributedString *songInfoString = [[NSMutableAttributedString alloc] initWithString: labelText
                                                                                       attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                                      NSFontAttributeName: HELV_16,
                                                                                                      NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    [songInfoString addAttribute:NSFontAttributeName value: HELV_LIGHT_14
                           range:NSMakeRange([title length] + 1, [subtitle length])];
    
    [label setAttributedText:songInfoString];
    
    return label;
}

- (UILabel *)createiTunesLabel
{
    UILabel *iTunesLabel = [[UILabel alloc] initWithFrame:CGRectMake(150.0f, YOUTUBE_LINK_ROW_HEIGHT + 10.0f, 150.0f, 25.0f)];
    
    iTunesLabel.text = @"Available on iTunes";
    iTunesLabel.font = GILL_16;
    iTunesLabel.textColor = HYPERLINK_BLUE;
    iTunesLabel.highlightedTextColor = DARK_BLUE_GRAY;
    iTunesLabel.textAlignment = NSTextAlignmentRight;
    
    // hyperlink
    UITapGestureRecognizer *linkPressed = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(iTunesLinkPressed:)];
    linkPressed.delegate = self;
    linkPressed.numberOfTapsRequired = 1;
    linkPressed.cancelsTouchesInView = NO;
    
    iTunesLabel.userInteractionEnabled = YES;
    [iTunesLabel addGestureRecognizer:linkPressed];
    
    return iTunesLabel;
}

- (UIButton *)createiTunesPreviewButton
{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(20.0f, YOUTUBE_LINK_ROW_HEIGHT + 10.0f, 85.0f, 25.0f)];
    
    // image
    UIImage *playIcon = [UIImage imageNamed:@"glyphicons_173_play"];
    playIcon = [Constants renderImage:playIcon inColor:HYPERLINK_BLUE];
    playIcon = [UIImage imageWithCGImage:playIcon.CGImage
                                   scale:playIcon.scale * 1.9
                             orientation:UIImageOrientationUp];
    
    UIImage *pauseIcon = [UIImage imageNamed:@"glyphicons_174_pause"];
    pauseIcon = [Constants renderImage:pauseIcon inColor:HYPERLINK_BLUE];
    pauseIcon = [UIImage imageWithCGImage:pauseIcon.CGImage
                                    scale:pauseIcon.scale * 2.0
                              orientation:UIImageOrientationUp];

    [button setImage:playIcon forState:UIControlStateNormal];
    [button setImage:pauseIcon forState:UIControlStateSelected];
    
    // label
    [button setTitle:@"Preview" forState:UIControlStateNormal];
    [button setTitleColor:HYPERLINK_BLUE forState:UIControlStateNormal];
    button.titleLabel.font = GILL_16;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;

    // layout
    CGFloat spacing = 10.0f; // spacing between image and title
    button.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 2.0f, spacing);
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, spacing, 0.0f, 0.0f);
    
    // add target
    [button addTarget:self action:@selector(iTunesPreviewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

/*- (UIButton *)createiTunesButton
{
    UIImage *iTunesBadge = [UIImage imageNamed:@"Available_on_iTunes"];
    iTunesBadge = [UIImage imageWithCGImage:iTunesBadge.CGImage
                                      scale:iTunesBadge.scale * 2.5
                                orientation:iTunesBadge.imageOrientation];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(150.0f, YOUTUBE_LINK_ROW_HEIGHT + 5.0f, iTunesBadge.size.width, iTunesBadge.size.height)];
    
    [button setImage:iTunesBadge forState:UIControlStateNormal];
    [button sizeToFit];
    
    // add target
    [button addTarget:self action:@selector(iTunesBadgePressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}*/

- (UIButton *)toolbarButtonWithNormalIcon:(UIImage *)normalIcon selectedIcon:(UIImage *)selectedIcon text:(NSString *)text action:(SEL)selector
{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 42.0f)];
    
    // images
    UIImage *normalImage = [UIImage imageWithCGImage:normalIcon.CGImage
                                               scale:(normalIcon.scale * 1.6) // scale down
                                         orientation:normalIcon.imageOrientation];
    normalImage = [Constants renderImage:normalImage inColor:[UIColor whiteColor]];
    
    UIImage *selectedImage = [UIImage imageWithCGImage:selectedIcon.CGImage
                                                 scale:(selectedIcon.scale * 1.6) // scale down
                                           orientation:selectedIcon.imageOrientation];
    selectedImage = [Constants renderImage:selectedImage inColor:[UIColor whiteColor]];
    
    [button setImage:normalImage forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateSelected];
    //[button sizeToFit];
    
    // label
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 30.0f, 50.0f, 12.0f)];
    textLabel.text = text;
    textLabel.textColor = [UIColor whiteColor];
    textLabel.font = [UIFont systemFontOfSize:9.0];
    textLabel.textAlignment = NSTextAlignmentCenter;
    
    CGFloat buttonHeight = button.frame.size.height;
    CGFloat buttonWidth = button.frame.size.width;
    CGFloat textHeight = textLabel.frame.size.height;
    CGFloat imageHeight = normalImage.size.height;
    CGFloat imageWidth = normalImage.size.width;
    
    // add elements
    button.imageEdgeInsets = UIEdgeInsetsMake((buttonHeight  - textHeight - imageHeight)/2.0f,
                                              (buttonWidth - imageWidth)/2.0f,
                                              (buttonHeight  - textHeight - imageHeight)/2.0f + textHeight,
                                              (buttonWidth - imageWidth)/2.0f);
    [button addSubview:textLabel];
    
    /*
     [button setTitle:text forState:UIControlStateNormal];
     [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
     button.titleLabel.font = [UIFont systemFontOfSize:9.0];
     button.titleLabel.textAlignment = NSTextAlignmentCenter;
     
     // Image/title inset code - stack overflow
     
     // the space between the image and text
     CGFloat spacing = 4.0;
     
     // lower the text and push it left so it appears centered below the image
     CGSize imageSize = button.imageView.frame.size;
     button.titleEdgeInsets = UIEdgeInsetsMake(0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
     
     // raise the image and push it right so it appears centered above the text
     CGSize titleSize = button.titleLabel.frame.size;
     button.imageEdgeInsets = UIEdgeInsetsMake(- (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
     */
    
    // add target
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

@end
