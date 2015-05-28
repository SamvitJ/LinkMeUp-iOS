//
//  musicStreamingViewController.m
//  echoprint
//
//  Created by Samvit Jain on 6/13/14.
//
//

#import "musicStreamingViewController.h"

#import "Constants.h"

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

@interface musicStreamingViewController ()

@property (nonatomic) BOOL queryVEVOLoaded;
@property (nonatomic) BOOL queryNonVEVOLoaded;

@property (nonatomic, strong) NSString *searchTerm;

// video Ids for best results
@property (nonatomic, strong) NSString *bestVEVO;
@property (nonatomic, strong) NSString *bestNonVEVO;

@end

@implementation musicStreamingViewController


#pragma mark - UI action methods

- (void)replyButtonPressed:(id)sender
{
    /*if (!self.replyVC)
    {
        self.replyVC = [[replyViewController alloc] init];
        self.replyVC.selectedLink = self.selectedLink;
    }*/
    
    self.replyVC = [[replyViewController alloc] init];
    self.replyVC.selectedLink = self.selectedLink;
    
    // load messages
    if (self.isSentLink)
    {
        for (NSMutableDictionary *receiverInfo in self.selectedLink.receiversData)
        {
            if ([[receiverInfo objectForKey:@"identity"] isEqualToString:@"QBjQaNUYOW"])
            {
                self.replyVC.messages = [receiverInfo objectForKey:@"messages"];
            }
        }
    }
    
    else
    {
        PFUser *me = [PFUser currentUser];
        for (NSMutableDictionary *receiverInfo in self.selectedLink.receiversData)
        {
            if ([[receiverInfo objectForKey:@"identity"] isEqualToString: me.objectId])
            {
                self.replyVC.messages = [receiverInfo objectForKey:@"messages"];
            }
        }
    }
    
    [self.navigationController pushViewController:self.replyVC animated:YES];
}

#pragma mark - Scroll view and web view delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.contentSize.height);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
    
    if ([webView respondsToSelector:@selector(scrollView)])
    {
        [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.zoom = 0.65;"];
        
        NSString* js =
        @"var meta = document.createElement('meta'); "
        "meta.setAttribute( 'name', 'viewport' ); "
        "meta.setAttribute( 'content', 'width = 320' ); "
        "document.getElementsByTagName('head')[0].appendChild(meta)";
        
        [webView stringByEvaluatingJavaScriptFromString: js];
    }
}

#pragma mark - Swipe gestures

- (IBAction)swipeLeft:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in each section
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    if (indexPath.section == kLinkYoutube)
    {
        CellIdentifier = @"Link";
    }
    else if (indexPath.section == kLinkMessage)
    {
        CellIdentifier = @"Message";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - Table view delegate

/*- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(18.0f, 8.0f, tableView.frame.size.width, 20.0f)];
    
    [label setFont:[UIFont boldSystemFontOfSize:16]];
    
    if (section == kLinkYoutube)
        [label setText:@"The Link"];

    else if (section == kLinkMessage)
        [label setText:@"The Message"];
    
    [view addSubview:label];
    
    [view setBackgroundColor:SECTION_HEADER_GRAY];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SECTION_HEADER_HEIGHT + 3.0f;
}*/

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        return 195.0;
    
    else if (indexPath.section == 1)
        return 70.0f;
    
    else return 0;
}

#pragma mark - View Controller lifecycle

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
    self.table.delegate = self;
    self.table.dataSource = self;
    
    // YouTube queries
    self.queryNonVEVOLoaded = NO;
    self.queryVEVOLoaded = NO;
    self.searchTerm = [[self.selectedLink.title stringByAppendingString:@" "] stringByAppendingString:self.selectedLink.artist];
    
    GTLServiceYouTube *youtubeService = [[GTLServiceYouTube alloc] init];
    youtubeService.APIKey = YOUTUBE_API_KEY;
    
    // VEVO video query
    GTLQueryYouTube *videoQueryVEVO = [GTLQueryYouTube queryForSearchListWithPart:@"id,snippet"];
    
    videoQueryVEVO.maxResults = 3;
    videoQueryVEVO.q = self.searchTerm;
    videoQueryVEVO.type = @"video";
    
    [youtubeService executeQuery:videoQueryVEVO
               completionHandler:^(GTLServiceTicket *ticket,
                                   id object, NSError *error) {
                   if (!error)
                   {
                       GTLYouTubeSearchListResponse *vids = object;
                       
                       //NSLog(@"VEVO Query Results **************************\n\n");
                       for (int i = 0; i < [vids.items count]; i++)
                       {
                           GTLYouTubeSearchResult *result = vids.items[i];
                           GTLYouTubeResourceId *identifier = result.identifier;
                           GTLYouTubeSearchResultSnippet *snippet = result.snippet;
                           
                           NSString *videoTitle = snippet.title;
                           NSString *videoId = [identifier.JSON objectForKey:@"videoId"];
                           NSString *videoChannel = [snippet.JSON objectForKey:@"channelTitle"];
                           
                           //NSLog(@"Title: %@", videoTitle);
                           //NSLog(@"Video Id: %@", videoId);
                           //NSLog(@"Channel: %@\n\n", videoChannel);
                           
                           // if channel title contains string 'VEVO', select video
                           if ([videoChannel rangeOfString:@"VEVO" options:NSCaseInsensitiveSearch].location != NSNotFound)
                           {
                               self.bestVEVO = videoId;
                               break;
                           }
                       }
                       
                       self.queryVEVOLoaded = YES;
                       [self loadVideo];
                   }
                   
                   else
                   {
                       NSLog(@"%@", [error userInfo]);
                   }
               }];
    
    // best non-VEVO video
    NSMutableString *identifierList = [[NSMutableString alloc] init];
    GTLQueryYouTube *videoQueryNonVEVO = [GTLQueryYouTube queryForSearchListWithPart:@"id,snippet"];
    
    videoQueryNonVEVO.videoSyndicated = @"true";
    //videoQuery.videoEmbeddable = @"true";
    
    videoQueryNonVEVO.maxResults = 10;
    videoQueryNonVEVO.q = self.searchTerm;
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
                        NSString *videoTitle = videoSnippet.title;
                        NSString *videoChannel = videoSnippet.channelTitle;
                        NSNumber *videoDuration = [self ISO8601FormatToFloatSeconds:videoDetails.duration];
                        NSNumber *videoViews = videoStatistics.viewCount;
                    
                        // score video
                        float currentVideoScore = 100.0f;
                        currentVideoScore += [self truncatedLengthScoreForTitle:videoTitle];
                        currentVideoScore += [self bannedKeywordScoreForTitle:videoTitle];
                        currentVideoScore += [self favoredKeywordScoreForTitle:videoTitle];
                        currentVideoScore += [self scoreForRank:i];
                        currentVideoScore += [self scoreForViews:[videoViews intValue]];
                        currentVideoScore += [self scoreForDuration:[videoDuration floatValue]];
                        
                        videoScores[i] = [[NSDictionary alloc] initWithObjects:@[videoId, [NSNumber numberWithFloat:currentVideoScore]]
                                                                       forKeys:@[@"videoId", @"score"]];
                        
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
                    self.bestNonVEVO = [videoScores[bestVideoIndex] objectForKey:@"videoId"];
                    NSLog(@"Winning video: %@", self.bestNonVEVO);
                    
                    self.queryNonVEVOLoaded = YES;
                    [self loadVideo];
                }
                    
                else
                {
                    NSLog(@"%@", [error userInfo]);
                }
             }];
         }
         
         else
         {
             NSLog(@"%@", [error userInfo]);
         }
                                                     
     }];
}

- (void)viewDidAppear:(BOOL)animated
{
    // link cell
    NSIndexPath *pathForLinkCell = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell *linkCell = [self.table cellForRowAtIndexPath:pathForLinkCell];
    
    if (!self.queryVEVOLoaded || !self.queryNonVEVOLoaded)
    {
        // initialize activity indicator
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicator.transform = CGAffineTransformMakeScale(2.0f, 2.0f);
        self.activityIndicator.center = CGPointMake(linkCell.bounds.size.width / 2.0, linkCell.bounds.size.height / 3.0);
        [self.activityIndicator startAnimating];
        [linkCell addSubview: self.activityIndicator];
    
        // action toolbar
        self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 382.0f, self.view.bounds.size.height, 49.0f)];
        self.toolbar.barTintColor = TURQ;
        self.toolbar.tintColor = [UIColor whiteColor];
        
        // draw reply button icon
        UIImage *replyIcon = [self drawText:@"Reply" onImage:[UIImage imageNamed:@"replyButton2.png"]];

        UIBarButtonItem *reply = [[UIBarButtonItem alloc] initWithImage: replyIcon
                                                                  style: UIBarButtonItemStylePlain
                                                                 target: self
                                                                 action: @selector(replyButtonPressed:)];

        [self.toolbar setItems: [NSArray arrayWithObjects: reply, nil]];
        
        [self.view addSubview: self.toolbar];
    }
}

- (UIImage *)drawText:(NSString *)myText onImage:(UIImage *)myImage
{
    UIImage *image = myImage;
    image = [UIImage imageWithCGImage:[image CGImage]
                                scale:(image.scale * 3.8)
                          orientation:(image.imageOrientation)];
    NSString *text = myText;
    
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0.0f, 0.0f, image.size.width, image.size.height)];
    
    CGRect rect = CGRectMake(0.0f, image.size.height * 0.75f, image.size.width, image.size.height * 0.25f);
    [[UIColor whiteColor] set];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    UIFont *font = [UIFont systemFontOfSize:9];
    NSDictionary *attributes = @{NSFontAttributeName: font,
                                 NSParagraphStyleAttributeName: paragraphStyle};
    
    [text drawInRect:rect withAttributes:attributes];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)loadVideo
{
    if (self.queryVEVOLoaded && self.queryNonVEVOLoaded)
    {
        NSLog(@"Loaded");
        
        // choose VEVO or nonVEVO (if VEVO is null)
        NSString *videoId = (self.bestVEVO ? self.bestVEVO : self.bestNonVEVO);
        
        // embedded playing
        //NSDictionary *playerVars = @{@"playsinline" : @1,};
        //[self.playerView loadWithVideoId:videoId]; //playerVars:playerVars];
        //[self.playerView playVideo];
        
        // load request
        NSString *URL = [[NSString stringWithFormat:@"https://www.youtube.com/watch?v="] stringByAppendingString:videoId];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
        
        
        // link cell
        NSIndexPath *pathForLinkCell = [NSIndexPath indexPathForRow:0 inSection:0];
        UITableViewCell *linkCell = [self.table cellForRowAtIndexPath:pathForLinkCell];
        
        // create web view
        UIWebView *myWebView = [[UIWebView alloc] init];
        myWebView.frame = CGRectMake(0.0f, 0.0f, 320.0f, 190.0f);
        myWebView.scrollView.scrollEnabled = NO;
        myWebView.delegate = self;
        [myWebView loadRequest: request];
        
        // add web view to link cell
        [linkCell addSubview: myWebView];
        
        
        // message cell
        NSIndexPath *pathForMessageCell = [NSIndexPath indexPathForRow:0 inSection:1];
        UITableViewCell *messageCell = [self.table cellForRowAtIndexPath:pathForMessageCell];
        
        // create message label
        UITextView *annotationView = [[UITextView alloc] initWithFrame:CGRectMake((messageCell.bounds.size.width - 300.0f)/2, 10.0f, 300.0f, 50.0f)];
        annotationView.backgroundColor = [UIColor clearColor];
        
        annotationView.scrollEnabled = NO;
        annotationView.textAlignment = NSTextAlignmentCenter;
        annotationView.textColor = BLUE_GRAY;
        annotationView.font = HELV_16;
        annotationView.text = self.selectedLink.annotation;
        annotationView.editable = NO;
        
        // add message label to message cell
        [messageCell addSubview: annotationView];
        
        
        /* // song cell
         NSIndexPath *pathForSongCell = [NSIndexPath indexPathForRow:0 inSection:0];
         UITableViewCell *songCell = [self.table cellForRowAtIndexPath:pathForSongCell];
         
         // create song label
         UILabel *songLabel = [[UILabel alloc] initWithFrame:CGRectMake((songCell.bounds.size.width - 300.0f)/2, 0.0f, 300.0f, 40.0f)];
         songLabel.text = [[self.songTitle stringByAppendingString:@"   "] stringByAppendingString:self.songArtist];
         songLabel.textColor = DARK_BLUE_GRAY;
         songLabel.font = HELV_16;
         
         // add song label to song cell
         [songCell addSubview: songLabel];*/
    }
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - YouTube format methods

- (NSNumber *)ISO8601FormatToFloatSeconds:(NSString *)duration
{
    NSString *formatString = [duration copy];
    
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    
    formatString = [formatString substringFromIndex:[formatString rangeOfString:@"T"].location];
    
    //only one letter remains after parsing
    while ([formatString length] > 1)
    {
        // remove first char (T, H, M, or S)
        formatString = [formatString substringFromIndex:1];
        
        NSScanner *scanner = [[NSScanner alloc] initWithString:formatString];
        
        // extract next integer in format string
        NSString *nextInteger = [[NSString alloc] init];
        [scanner scanCharactersFromSet:DIGITS_SET intoString:&nextInteger];
        
        // determine range of next integer
        NSRange rangeOfNextInteger = [formatString rangeOfString:nextInteger];
        
        // delete parsed integer from format string
        formatString = [formatString substringFromIndex:rangeOfNextInteger.location + rangeOfNextInteger.length];
        
        if ([[formatString substringToIndex:1] isEqualToString:@"H"])
            hours = [nextInteger intValue];
        
        else if ([[formatString substringToIndex:1] isEqualToString:@"M"])
            minutes = [nextInteger intValue];
        
        else if ([[formatString substringToIndex:1] isEqualToString:@"S"])
            seconds = [nextInteger intValue];
    }
    
    //NSLog(@"Video length (seconds): %f", (hours * 3600.0) + (minutes * 60.0) + (seconds * 1.0));
    return [NSNumber numberWithFloat:((hours * 3600.0) + (minutes * 60.0) + (seconds * 1.0))];
}

#pragma mark - Search result scoring methods

- (float)scoreForDuration:(float)resultDuration
{
    float score;
    
    if (abs(resultDuration - [self.selectedLink.duration floatValue]) <= 3.0f)
        score = 30.0f;
    
    else if (abs(resultDuration - [self.selectedLink.duration floatValue])/[self.selectedLink.duration floatValue] <= 0.03f)
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
    
    NSString *songDescription = [[self.searchTerm stringByAppendingString:@" "] stringByAppendingString:self.selectedLink.album];
    
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
    
    
    if ((!isInstrumental && isResultInstrumental) || (!isCover && isResultCover)  || (!isTutorial && isResultTutorial) || (!isParody && isResultParody))
        score = -60.0f;
    
    else if ((!isRemix && isResultRemix) || (!isMix && isResultMix) ||(!isRemake && isResultRemake) || (!isScrewed && isResultScrewed) || (!isChopped && isResultChopped))
        score = -45.0f;
    
    else if (!isLive && isResultLive)
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
    NSString *title = [[self.selectedLink.title componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@""];
    NSString *artist = [[self.selectedLink.artist componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@""];
    NSString *album = [[self.selectedLink.album componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@""];
    NSArray *otherWords = [@"lyrics", @"lyric", @"official", @"original"];
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

@end
