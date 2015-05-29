//
//  echoprintViewController.m
//  echoprint
//
//  Created by Brian Whitman on 6/13/11.
//  Copyright 2011 The Echo Nest. All rights reserved.
//

#import "echoprintViewController.h"

#import "ASIHTTPRequest.h"
#import <Parse/Parse.h>
#import <FacebookSDK/FacebookSDK.h>

#import "Constants.h"

#import "DefaultSettingsViewController.h"

@interface echoprintViewController ()
{
    // used by -(IBAction)useAmbient:(id)sender
    AVAudioRecorder *myRecorder;
    AVAudioPlayer *myPlayer;
}

@end

@implementation echoprintViewController


#pragma mark - Data initialization

- (Data *)sharedData
{
    if (!_sharedData)
    {
        echoprintAppDelegate *appDelegate = (echoprintAppDelegate *)[[UIApplication sharedApplication] delegate];
        _sharedData = appDelegate.myData;
        return _sharedData;
    }
    
    else return _sharedData;
}

#pragma mark - Swipe gestures

- (IBAction)swipeRight:(id)sender
{
    UITabBarController *myTBC = (UITabBarController *)[self.navigationController parentViewController];
    myTBC.selectedViewController = myTBC.viewControllers[kTabBarIconInbox];
}

- (IBAction)swipeLeft:(id)sender
{
    UITabBarController *myTBC = (UITabBarController *)[self.navigationController parentViewController];
    myTBC.selectedViewController = myTBC.viewControllers[kTabBarIconFriends];
}

#pragma mark - UI action methods

- (IBAction)addMessage:(id)sender
{
    if ([[self.currentSongLabel.text stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""] || [[self.currentArtistLabel.text stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""])
    {
        return;
    }
    
    self.idDisable = YES;

    /*if (!self.messageVC)
    {
        self.messageVC = [[messageViewController alloc] init];
    }*/
    
    self.sharedData.iTunesTitle = self.currentSongLabel.text;
    self.sharedData.iTunesArtist = [self.currentArtistLabel.text stringByReplacingOccurrencesOfString:@"by " withString:@""];
    self.sharedData.iTunesAlbum = self.currentAlbumLabel;
    
    //[self.navigationController pushViewController:self.messageVC animated:YES];
}

- (IBAction)justSend:(id)sender
{
    if ([[self.currentSongLabel.text stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""] ||
        [[self.currentArtistLabel.text stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""])
    {
        return;
    }
    
    self.idDisable = YES;
    
    if (!self.contactsVC)
    {
        self.contactsVC = [[contactsViewController alloc] init];
    }
    
    self.sharedData.iTunesTitle = self.currentSongLabel.text;
    self.sharedData.iTunesArtist = [self.currentArtistLabel.text stringByReplacingOccurrencesOfString:@"by " withString:@""];
    self.sharedData.iTunesAlbum = self.currentAlbumLabel;
    self.sharedData.annotation = @"";

    [self.navigationController pushViewController:self.contactsVC animated:YES];
}

- (IBAction)tryAgainPressed:(id)sender
{
    self.shouldRefresh = YES;
    
    NSDictionary *info = self.songInformation;
    
    NSMutableString *firstLine = [NSMutableString stringWithFormat:@""];
    NSMutableString *secondLine = [NSMutableString stringWithFormat:@""];
    NSString *album;
    
    if ([[info valueForKey:@"title"] isEqualToString:self.currentSongLabel.text])
    {
        self.statusLabel.text = @"Identifying current song...";
    }
    
    else if (self.foundSong)
    {
        self.statusLabel.text = @"Send:  ";
        [firstLine appendString:[info valueForKey:@"title"]];
        [secondLine appendString:@"by  "];
        [secondLine appendString:[info valueForKey:@"artist"]];
        
        album = [info valueForKey:@"album"];
        
        self.shouldRefresh = NO;
    }
    
    else
    {
        self.statusLabel.text = @"No match.  Trying again...";
    }
    
    self.currentSongLabel.text = firstLine;
    self.currentArtistLabel.text = secondLine;
    self.currentAlbumLabel = album;
}

- (IBAction)playSample:(id)sender
{
    if (self.recording)
    {
        self.recording = NO;
        [self.recorder stopRecording];
        
		[self.statusLine setText:@"Playing..."];
        [self.playButton setTitle:@"Stop" forState:UIControlStateNormal];
        
        [self.recorder playRecording:self];
    }
    
    else
    {
        [self.recorder stopPlaying];
        [self.playButton setTitle:@"Play Sample" forState:UIControlStateNormal];
        
        [self startMicrophone:nil];
    }
    
    /*[myRecorder stop];
     myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:myRecorder.url error:nil];
     [myPlayer setDelegate:self];
     myPlayer.volume = 1.0;
     [myPlayer play];*/
}

/*
- (IBAction)pickSong:(id)sender
{
    NSLog(@"Pick song");
	MPMediaPickerController* mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
     mediaPicker.delegate = self;
     [self presentViewController:mediaPicker animated:YES completion:nil];
}

- (IBAction)useAmbient:(id)sender
{
    [myRecorder stop];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    
    NSURL* assetURL = myRecorder.url;
    
    // set up destination URL
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSURL* destinationURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"temp_data"]];
    [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
    
    TSLibraryImport* import = [[TSLibraryImport alloc] init];
    [import importAsset:assetURL toURL:destinationURL completionBlock:^(TSLibraryImport* import) {
        //check the status and error properties of
        //TSLibraryImport
        NSString *outPath = [documentsDirectory stringByAppendingPathComponent:@"temp_data"];
        NSLog(@"done now. %@", outPath);
        [self.statusLine setText:@"analysing..."];
        
        NSString* fpCode = [FPGenerator generateFingerprintForFile:outPath];
        
        [self.statusLine setNeedsDisplay];
        [self.view setNeedsDisplay];
        [self getSong:fpCode];
    }];
}
*/

- (void)startMicrophone:(id)sender
{
	if (self.recording)
    {
		self.recording = NO;
		[self.recorder stopRecording];
		//[self.recordButton setTitle:@"Record" forState:UIControlStateNormal];
        
        // (re)determine file URL
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = paths[0];
		NSString *filePath =[documentsDirectory stringByAppendingPathComponent:@"output.caf"];
        
		[self.statusLine setText:@"Analyzing..."];
		[self.statusLine setNeedsDisplay];
		[self.view setNeedsDisplay];
        
        dispatch_queue_t otherQ = dispatch_queue_create("FPGen+getSong", NULL);
        dispatch_async(otherQ, ^{
            NSString* fpCode = [FPGenerator generateFingerprintForFile:filePath];
            [self getSong:fpCode];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (self.shouldRefresh)
                {
                    NSMutableString *firstLine = [NSMutableString stringWithFormat:@""];
                    NSMutableString *secondLine = [NSMutableString stringWithFormat:@""];
                    NSString *album;
                    
                    NSDictionary *info = self.songInformation;
                    if (self.foundSong)
                    {
                        self.statusLabel.text = @"Send:  ";
                        [firstLine appendString:[info valueForKey:@"title"]];
                        [secondLine appendString:@"by  "];
                        [secondLine appendString:[info valueForKey:@"artist"]];
                        
                        album = [info valueForKey:@"artist"];
                        
                        self.shouldRefresh = NO;
                    }
                    
                    else
                    {
                        self.statusLabel.text = @"No match.  Trying again...";
                    }
                    
                    self.currentSongLabel.text = firstLine;
                    self.currentArtistLabel.text = secondLine;
                    self.currentAlbumLabel = album;
                }
                
                self.startDate = [NSDate date];
                [self startMicrophone:nil]; // restart mic
            });
        });
	}
    
    else
    {
		[self.statusLine setText:@"Recording..."];
		self.recording = YES;
		//[self.recordButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self.recorder startRecording:self];
		[self.statusLine setNeedsDisplay];
		[self.view setNeedsDisplay];
	}
}

#pragma mark - Delegate and notification methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    // log recording error
    NSLog(@"%@ %@", error, [error userInfo]);
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"Reached");
    
    [self.recorder stopPlaying];
    [self.playButton setTitle:@"Play Sample" forState:UIControlStateNormal];
    
    [self startMicrophone:nil];
}

- (void)audioSessionRouteChanged:(NSNotification *)notification
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = [audioSession currentRoute];
    
    self.isHeadsetInUse = NO;
    for (AVAudioSessionPortDescription *output in currentRoute.outputs)
    {
        if ([[output portType] isEqualToString:AVAudioSessionPortHeadphones])
        {
            self.isHeadsetInUse = YES;
            //NSLog(@"Headset in use");
            
            //[audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            
            /*
            NSError *micError;
            if (![audioSession setPreferredInput:output error:&micError])
            {
                NSLog(@"Error: %@", [micError localizedDescription]);
            }
            else
            {
                NSLog(@"setPreferredInput succeeded");
                myRecorder.channelAssignments = output.channels;
            }*/
        }
    }
    
    if (!self.isHeadsetInUse)
    {
        //NSLog(@"Headset unplugged");
        //[audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }
    
    //[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    //[audioSession setActive:YES error:nil];
    
    
    /*
     NSDictionary *interuptionDict = notification.userInfo;
     NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
     
     switch (routeChangeReason)
     {
     case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
     NSLog(@"AVAudioSessionRouteChangeReasonNewDeviceAvailable");
     NSLog(@"Headphone/Line plugged in");
     break;
     
     case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
     NSLog(@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
     NSLog(@"Headphone/Line was pulled.");
     self.isHeadsetInUse = NO;
     break;
     
     case AVAudioSessionRouteChangeReasonCategoryChange:
     // called at start - also when other audio wants to play
     NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
     break;
     }*/
}

#pragma mark - Internal functionality

- (void)updateTimer
{
    if (self.idDisable)
    {
        if (self.recording)
        {
            [self.recorder stopRecording];
            self.recording = NO;
        }
        
        return;
    }
    
    if (!self.myTimer)
    {
        self.myTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                                                        target:self
                                                      selector:@selector(updateTimer)
                                                      userInfo:nil
                                                       repeats:YES];
    }
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:self.startDate];
    
    if (timeInterval >= 12 && self.recording)
    {
        [self startMicrophone:nil]; // stop mic, do codegen, update song info label
    }
}

/*- (void)mediaPicker:(MPMediaPickerController *)mediaPicker
  didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
	[self dismissViewControllerAnimated:YES completion:nil];
    
	for (MPMediaItem* item in mediaItemCollection.items)
    {
		NSString* title = [item valueForProperty:MPMediaItemPropertyTitle];
		NSURL* assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
		NSLog(@"title: %@, url: %@", title, assetURL);
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = paths[0];

		NSURL* destinationURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"temp_data"]];
		[[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
		TSLibraryImport* import = [[TSLibraryImport alloc] init];
		[import importAsset:assetURL toURL:destinationURL completionBlock:^(TSLibraryImport* import) {
			//check the status and error properties of
			//TSLibraryImport
			NSString *outPath = [documentsDirectory stringByAppendingPathComponent:@"temp_data"];
			NSLog(@"done now. %@", outPath);
			[self.statusLine setText:@"Analyzing..."];
			
            NSString* fpCode = [FPGenerator generateFingerprintForFile:outPath];
            
			[self.statusLine setNeedsDisplay];
			[self.view setNeedsDisplay];
			[self getSong:fpCode];
		}];
	}
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
	[self dismissViewControllerAnimated:YES completion:nil];
}*/

- (void)getSong:(NSString*)fpCode
{
	//NSLog(@"GetSong done %@", fpCode);

    NSString *apiString = [NSString stringWithFormat:@"http://%@/api/v4/song/identify?api_key=%@&version=4.11&code=%@&format=json", ECHONEST_API_HOST, ECHONEST_API_KEY, fpCode];
    
    NSURL *url = [NSURL URLWithString:apiString];
	
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setAllowCompressedResponse:NO];
    [request startSynchronous];
    
	NSError *error = [request error];
    
	if (!error)
    {
		NSString *response = [[NSString alloc] initWithData:[request responseData] encoding: NSUTF8StringEncoding];
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
		NSLog(@"%@", dictionary);
		NSArray *songList = dictionary[@"response"][@"songs"];
        
		if ([songList count] > 0)
        {
            // album retrieval code *****************
            NSString *profileQuery = [NSString stringWithFormat:@"http://%@/api/v4/song/profile?api_key=%@&format=json&id=%@&bucket=tracks&bucket=id:spotify", ECHONEST_API_HOST, ECHONEST_API_KEY, songList[0][@"id"]];
            NSURL *profileURL = [NSURL URLWithString:profileQuery];
            
            ASIHTTPRequest *profileRequest = [ASIHTTPRequest requestWithURL:profileURL];
            [profileRequest setAllowCompressedResponse:NO];
            [profileRequest startSynchronous];
            
            NSString *album_name;
            if (![profileRequest error])
            {
                NSString *albumResponse = [[NSString alloc] initWithData:[profileRequest responseData] encoding: NSUTF8StringEncoding];
                NSDictionary *albumDictionary = [NSJSONSerialization JSONObjectWithData:[albumResponse dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                NSArray *songListDetailed = albumDictionary[@"response"][@"songs"];
                NSArray *trackInfo = songListDetailed[0][@"tracks"];
                
                if ([trackInfo count])
                    album_name = trackInfo[0][@"album_name"];
                
                NSLog(@"Album: %@", album_name);
            }
            else
            {
                NSLog(@"Error getting album name from spotify %@", [profileRequest error]);
            }
            // **************************************
            
			NSString *song_title = songList[0][@"title"];
			NSString *artist_name = songList[0][@"artist_name"];
            
            if (song_title && artist_name)
            {
                self.foundSong = YES;
            
                [self.songInformation setObject:(NSString *)song_title forKey:(NSString *)@"title"];
                
                [self.songInformation setObject:(NSString *)artist_name forKey:(NSString *)@"artist"];
                
                if (album_name)
                    [self.songInformation setObject:(NSString *)album_name forKey:(NSString *)@"album"];
                
                [self.statusLine setText:[NSString stringWithFormat:@"%@ - %@", artist_name, song_title]];
            }

            else
            {
                self.foundSong = NO;
                [self.statusLine setText:@"No Match"];
            }
		}
        
        else
        {
            self.foundSong = NO;
			[self.statusLine setText:@"No Match"];
		}
        
	}
    
    else
    {
		[self.statusLine setText:@"Error in song ID"];
		NSLog(@"getSong: %@", error);
	}
    
	[self.statusLine setNeedsDisplay];
	[self.view setNeedsDisplay];
}

#pragma mark - Application lifecycle methods

- (void)viewWillAppear:(BOOL)animated
{
    self.idDisable = NO;
    
    if (self.recording)
		[self.statusLine setText:@"Recording..."];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleField.delegate = self;
    self.artistField.delegate = self;
    
    // Subscribe to route change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionRouteChanged:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];

    /*
    // Set the audio file to <Documents>/MyAudioMemo.caf
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];

    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
 
    // Initiate and prepare the recorder
    myRecorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
    myRecorder.delegate = self;
    myRecorder.meteringEnabled = YES;
    [myRecorder prepareToRecord];
    
    [session setActive:YES error:nil];

    // set input to output to headset output track
    AVAudioSessionRouteDescription *currentRoute = [session currentRoute];
    for (AVAudioSessionPortDescription *output in currentRoute.outputs)
    {
        if ([[output portType] isEqualToString:AVAudioSessionPortHeadphones])
        {
            self.isHeadsetInUse = YES;
            NSLog(@"Headset plugged in");
            
            [session setPreferredInput:output error:nil];
            
            for (AVAudioSessionChannelDescription *channel in output.channels)
            {
                NSLog(@"%@ - channel: %@", [output portType], channel.channelName);
            }
            
            myRecorder.channelAssignments = output.channels;
        }
    }
    
    for (AVAudioSessionPortDescription *input in currentRoute.inputs)
    {
        for (AVAudioSessionChannelDescription *channel in input.channels)
        {
            NSLog(@"%@ - channel: %@", [input portType], channel.channelName);
        }
    }
    
    NSLog(@"Preferred input: %@", [session.preferredInput portType]);
    
    // Start recording
    [myRecorder record];*/
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        NSLog(@"Echoprint VC  Hi!");
        
        self.recorder = [[MicrophoneInput alloc] init];
        self.recording = NO;
        
        self.startDate = [NSDate date];
        self.myTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                                                        target:self
                                                      selector:@selector(updateTimer)
                                                      userInfo:nil
                                                       repeats:YES];
        
        self.songInformation = [[NSMutableDictionary alloc] init];
        
        self.shouldRefresh = YES;
        self.idDisable = NO;
        self.foundSong = NO;
        
        [self audioSessionRouteChanged:nil];
        [self startMicrophone:nil]; // start mic
    }
    
    return self;
}

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

@end
