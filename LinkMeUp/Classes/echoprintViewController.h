//
//  echoprintViewController.h
//  echoprint
//
//  Created by Brian Whitman on 6/13/11.
//  Copyright 2011 The Echo Nest. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>  

// echonest
#import "TSLibraryImport.h"
#import "MicrophoneInput.h"
#import "FPGenerator.h"

// associated VCs
//#import "messageViewController.h"
#import "contactsViewController.h"

@interface echoprintViewController : UIViewController <MPMediaPickerControllerDelegate,AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITextFieldDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// recorder class
@property (strong, nonatomic) MicrophoneInput *recorder;

// song information
@property (strong, nonatomic) NSMutableDictionary *songInformation;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentSongLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentArtistLabel;
@property (strong, nonatomic) NSString *currentAlbumLabel;

// text fields
@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UITextField *artistField;

// timer components
@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSTimer *myTimer;

// associated VCs
//@property (strong, nonatomic) messageViewController *messageVC;
@property (strong, nonatomic) contactsViewController *contactsVC;

// status booleans
@property (nonatomic) BOOL recording;

@property (nonatomic) BOOL foundSong;
@property (nonatomic) BOOL shouldRefresh;
@property (nonatomic) BOOL idDisable;

@property (nonatomic) BOOL isHeadsetInUse;

// messenger IBActions
- (IBAction)addMessage:(id)sender;
- (IBAction)justSend:(id)sender;

// echoprint UI elements
//@property (weak, nonatomic) IBOutlet UIButton* recordButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel* statusLine;

// echoprint IBActions
//- (IBAction)pickSong:(id)sender;
//- (IBAction)useAmbient:(id)sender;
//- (IBAction)startMicrophone:(id)sender;
- (void)getSong:(NSString*)fpCode;

@end

