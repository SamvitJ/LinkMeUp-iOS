//
//  songInfoViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/10/14.
//
//

#import "songInfoViewController.h"

@interface songInfoViewController ()

@end

@implementation songInfoViewController


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

#pragma mark - Swipe gestures

- (void)swipeRight:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Text view delegate methods

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        if (self.annotationView.isFirstResponder)
        {
            [self.annotationView resignFirstResponder];
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

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendToPressed:(id)sender
{
    if (!self.contactsVC)
        self.contactsVC = [[contactsViewController alloc] init];
    
    // set contacts VC state
    self.contactsVC.isForwarding = self.isForwarding;
    self.sharedData.isSong = (self.isForwarding ? self.sharedData.isSong : YES);
    
    self.sharedData.annotation = ([self.annotationView.text isEqualToString:@"Add message"] ? @"" : self.annotationView.text);
    
    [self.navigationController pushViewController:self.contactsVC animated:YES];
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
    // Do any additional setup after loading the view from its nib
    
    // exit text fields gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    // disable sendTo button
    [Constants disableButton:self.sendToButton];
    
    // start activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = CGPointMake(self.view.frame.size.width / 2.0, 170.0f + (IS_IPHONE_5 ? 30.0f : 0.0f));
    [self.activityIndicator startAnimating];
    [self.view addSubview: self.activityIndicator];
    
    // add back button
    UIButton *backButton = [Constants createBackButtonWithText:(self.isForwarding ? @"Link" : @"Search")];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:backButton];
    
    // swipe left (back button)
    UISwipeGestureRecognizer *gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    [gestureRecognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:gestureRecognizer];
    
    if (!self.isForwarding)
    {
        // load song
        [self loadSong];
    }
    
    else
    {
        // fowarding song
        if (self.sharedData.isSong)
        {
            self.backgroundColor = BLUE_200;
            [self displaySongInfo];
        }
        
        else // forwarding video
        {
            self.backgroundColor = FAINT_GRAY;
            [self displayVideoInfo];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    // set background
    self.view.backgroundColor = self.backgroundColor;
    
    // if forwarding, change header color
    if (self.isForwarding)
        self.header.backgroundColor = PURPLE;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - iTunes Request

- (void)loadSong
{
    NSMutableString *songTitleKey = [NSMutableString stringWithString:self.sharedData.userTitle];
    NSMutableString *songArtistKey = [NSMutableString stringWithString:self.sharedData.userArtist];
    
    [songTitleKey replaceOccurrencesOfString:@" " withString:@"+" options:NSCaseInsensitiveSearch range:NSMakeRange(0, songTitleKey.length)];
    [songArtistKey replaceOccurrencesOfString:@" " withString:@"+" options:NSCaseInsensitiveSearch range:NSMakeRange(0, songArtistKey.length)];
    
    NSString *keyword = [[songTitleKey stringByAppendingString:@"+"] stringByAppendingString:songArtistKey];
    NSLog(@"%@", keyword);
    
    NSString *query = [NSString stringWithFormat:@"https://itunes.apple.com/search?term=%@&media=music&entity=musicTrack&limit=1", keyword];
    NSLog(@"%@", query);
    NSURL *url = [NSURL URLWithString:query];
    
    // iTunes query
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!error)
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSString *response = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                NSArray *results = [dictionary valueForKey:@"results"];
                
                NSLog(@"%@", results);
                
                NSDictionary *firstResult = [results firstObject];
                
                self.sharedData.iTunesTitle = [firstResult objectForKey:@"trackName"];
                self.sharedData.iTunesArtist = [firstResult objectForKey:@"artistName"];
                self.sharedData.iTunesAlbum = [firstResult objectForKey:@"collectionName"];
                self.sharedData.iTunesArt = [[firstResult objectForKey:@"artworkUrl100"] stringByReplacingOccurrencesOfString:@"100x100-75.jpg" withString:@"200x200-75.jpg"];
                self.sharedData.iTunesDuration = [NSNumber numberWithFloat:[[firstResult objectForKey:@"trackTimeMillis"] floatValue]/1000.0f];
                self.sharedData.iTunesURL = [firstResult objectForKey:@"trackViewUrl"];
                self.sharedData.iTunesPreviewURL = [firstResult objectForKey:@"previewUrl"];
                
                // if song found, display song info
                // else display "no match" label
                (self.sharedData.iTunesTitle ? [self displaySongInfo] : [self displayNoMatchLabel]);
            });
        }
        
        else
        {
            NSLog(@"Error fetching song data from iTunes %@ %@", error, [error userInfo]);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.activityIndicator stopAnimating];
                [self displayErrorLabel: error];
            });
        }
    }];
}

#pragma mark - UI helper methods

- (void)displayErrorLabel:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    
    // handle error
    NSString *errorMessage;
    int errorCode = (int)error.code;
    
    switch (errorCode)
    {
        case -1000:
            errorMessage = @"An error occurred :(\nSwipe right to try again";
            break;
            
        case -1005:
        case -1009:
            errorMessage = @"Couldn't find internet connection :(\n Swipe right to try again";
            break;
            
        default:
            errorMessage = @"An error occurred :(\n Swipe right to try again";
            break;
    }
    
    // error label
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineSpacing = 4.0;
    
    UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 300.0f)/2, 170.0f + (IS_IPHONE_5 ? 30.0f : 0.0f), 300.0f, 65.0f)];
    errorLabel.numberOfLines = 0;
    errorLabel.lineBreakMode = NSLineBreakByWordWrapping;
    errorLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:errorMessage
                                                                       attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                      NSFontAttributeName: HELV_18,
                                                                                      NSForegroundColorAttributeName: [UIColor whiteColor]}];

    
    [self.view addSubview:errorLabel];
}

- (void)displayNoMatchLabel
{
    [self.activityIndicator stopAnimating];
    
    // no match label
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineSpacing = 4.0;
    
    UILabel *noMatchLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 290.0f)/2, 170.0f + (IS_IPHONE_5 ? 30.0f : 0.0f), 290.0f, 65.0f)];
    noMatchLabel.numberOfLines = 0;
    noMatchLabel.lineBreakMode = NSLineBreakByWordWrapping;
    noMatchLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:(@"No match found.\nSwipe right to try again.")
                                                                       attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                      NSFontAttributeName: HELV_18,
                                                                                      NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    [self.view addSubview:noMatchLabel];
}

- (void)displayVideoInfo
{
    // video thumbnail
    NSURL *thumbnailURL = [NSURL URLWithString: self.sharedData.youtubeVideoThumbnail];
    
    // create URL session task
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:thumbnailURL
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.activityIndicator stopAnimating];
            
            // thumbnail art
            self.artImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:data]];
            [self.artImageView setFrame:(IS_IPHONE_5 ? CGRectMake(50.0f, 110.0f, 220.0f, 165.0f) : CGRectMake(70.0f, 95.0f, 180.0f, 135.0f))];
            
            // labels
            self.titleLabel = [[UILabel alloc] initWithFrame:(IS_IPHONE_5 ? CGRectMake(50.0f, 285.0f, 220.0f, 40.0f) : CGRectMake(70.0f, 235.0f, 180.0f, 40.0f))];
            self.titleLabel.font = GILL_14;
            self.titleLabel.textAlignment = NSTextAlignmentLeft;
            self.titleLabel.numberOfLines = 0;
            self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.titleLabel.text = self.sharedData.youtubeVideoTitle;
            
            self.channelLabel = [[UILabel alloc] initWithFrame:(IS_IPHONE_5 ? CGRectMake(50.0f, 325.0f, 115.0f, 15.0f) : CGRectMake(70.0f, 275.0f, 95.0f, 15.0f))];
            self.channelLabel.font = GILL_12;
            self.channelLabel.textColor = DARK_BLUE_GRAY;
            self.channelLabel.textAlignment = NSTextAlignmentLeft;
            self.channelLabel.numberOfLines = 0;
            self.channelLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.channelLabel.text = self.sharedData.youtubeVideoChannel;
            
            self.viewsLabel = [[UILabel alloc] initWithFrame:(IS_IPHONE_5 ? CGRectMake(168.0f, 326.0f, 102.0f, 15.0f) : CGRectMake(168.0f, 276.0f, 82.0f, 15.0f))];
            self.viewsLabel.font = GILL_10;
            self.viewsLabel.textColor = BLUE_GRAY;
            self.viewsLabel.textAlignment = NSTextAlignmentRight;
            self.viewsLabel.numberOfLines = 0;
            self.viewsLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.viewsLabel.text = [[NSNumberFormatter localizedStringFromNumber:self.sharedData.youtubeVideoViews numberStyle:NSNumberFormatterDecimalStyle] stringByAppendingString:@" views"];
            
            // add image and labels to view
            [self.view addSubview: self.artImageView];
            [self.view addSubview: self.titleLabel];
            [self.view addSubview: self.channelLabel];
            [self.view addSubview: self.viewsLabel];
            
            // enable button
            [Constants enableButton:self.sendToButton];
            
            // annotation text view
            [self displayAnnotationView];
        });

    }];
    
    // execute task
    [task resume];
}

- (void)displaySongInfo
{
    // album art
    NSURL *albumArtURL = [NSURL URLWithString:[self.sharedData.iTunesArt stringByReplacingOccurrencesOfString:@"200x200-75.jpg" withString:@"400x400-75.jpg"]];
    
    // create URL session task
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:albumArtURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.activityIndicator stopAnimating];
            
            // album art
            self.artImageView = [[UIImageView alloc] initWithImage: [UIImage imageWithData:data]];
            [self.artImageView setFrame:(IS_IPHONE_5 ? CGRectMake((self.view.bounds.size.width - 180.0f)/2, 110.0f, 180.0f, 180.0f) : CGRectMake((self.view.bounds.size.width - 150.0f)/2, 95.0f, 150.0f, 150.0f))];
            
            // title and artist labels
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.alignment = NSTextAlignmentCenter;
            
            self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 290.0f)/2, 255.0f + (IS_IPHONE_5 ? 50.0f : 0.0f), 290.0f, 30.0f)];
            self.titleLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:(self.sharedData.iTunesTitle ? self.sharedData.iTunesTitle : @"")
                                                                                    attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                                   NSFontAttributeName: HELV_22,
                                                                                                   NSForegroundColorAttributeName: [UIColor whiteColor]}];
            self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            
            self.artistLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 290.0f)/2, 285.0f + (IS_IPHONE_5 ? 50.0f : 0.0f), 290.0f, 20.0f)];
            self.artistLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:(self.sharedData.iTunesArtist ? self.sharedData.iTunesArtist : @"")
                                                                                     attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                                    NSFontAttributeName: HELV_16,
                                                                                                    NSForegroundColorAttributeName: [UIColor whiteColor]}];
            self.artistLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            
            // add image and labels to view
            [self.view addSubview:self.titleLabel];
            [self.view addSubview:self.artistLabel];
            [self.view addSubview:self.artImageView];
            
            // enable button
            [Constants enableButton:self.sendToButton];
            
            // annotation text view
            [self displayAnnotationView];
        });

    }];
    
    // execute task
    [task resume];
}

#pragma mark - UI helper methods

- (void)displayAnnotationView
{
    // annotation text view
    self.annotationView = [[UITextView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 300.0f)/2, 310.0f + (IS_IPHONE_5 ? 55.0f : 0.0f), 300.0f, 47.0f)];
    self.annotationView.backgroundColor = [UIColor clearColor];
    
    self.annotationView.scrollEnabled = NO;
    self.annotationView.textAlignment = NSTextAlignmentCenter;
    self.annotationView.textColor = (self.isForwarding && !self.sharedData.isSong ? HYPERLINK_BLUE : DARK_BLUE_GRAY);
    self.annotationView.font = HELV_16;
    self.annotationView.text = @"Add message";
    
    self.annotationView.delegate = self;
    [self.view addSubview:self.annotationView];
}

#pragma mark - Text view animation

- (void)animateContent:(UITextView *)textView inDirection:(Direction)direction
{
    float movementDistance = 108.0f;
    float movement = (direction ? movementDistance : -movementDistance);
    float movementDuration = 0.3f;
    
    [UIView beginAnimations:@"Scroll" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    
    [self.view bringSubviewToFront:self.header];
    
    self.titleLabel.frame = CGRectOffset(self.titleLabel.frame, 0.0f, movement);
    self.artistLabel.frame = CGRectOffset(self.artistLabel.frame, 0.0f, movement);
    
    if (self.isForwarding && !self.sharedData.isSong)
    {
        self.channelLabel.frame = CGRectOffset(self.channelLabel.frame, 0.0f, movement);
        self.viewsLabel.frame = CGRectOffset(self.viewsLabel.frame, 0.0f, movement);
    }
    
    self.artImageView.frame = CGRectOffset(self.artImageView.frame, 0.0f, movement);
    self.annotationView.frame = CGRectOffset(self.annotationView.frame, 0.0f, movement);
    
    [UIView commitAnimations];
}

@end
