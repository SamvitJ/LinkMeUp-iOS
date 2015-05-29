//
//  MicrophoneInput.m
//  Echoprint
//
//  Created by Brian Whitman on 1/23/11.
//  Copyright 2011 The Echo Nest. All rights reserved.
//

#import "MicrophoneInput.h"


@implementation MicrophoneInput

- (void)viewDidLoad
{
    [super viewDidLoad];
    recordEncoding = ENC_PCM;
}

- (IBAction)startRecording:(id)sender
{
	//NSLog(@"MicrophoneInput.mm  Starting recording");
	self.audioRecorder = nil;
	
	// Init audio with record capability
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive: NO error: nil];
	[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    
	NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] initWithCapacity:10];
	recordSettings[AVFormatIDKey] = @(kAudioFormatLinearPCM);
	recordSettings[AVSampleRateKey] = @44100.0f;
	recordSettings[AVNumberOfChannelsKey] = @2;
	recordSettings[AVLinearPCMBitDepthKey] = @16;
	recordSettings[AVLinearPCMIsBigEndianKey] = @NO;
	recordSettings[AVLinearPCMIsFloatKey] = @NO;   
	
	//set the export session's outputURL to <Documents>/output.caf
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = paths[0];
	NSURL* outURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"output.caf"]];
	[[NSFileManager defaultManager] removeItemAtURL:outURL error:nil];
	//NSLog(@"MicrophoneInput.mm  URL location %@", outURL);
    
	NSError *error = nil;
	self.audioRecorder = [[ AVAudioRecorder alloc] initWithURL:outURL settings:recordSettings error:&error];
    [self.audioRecorder setDelegate:sender];
	
    /*for (AVAudioSessionChannelDescription *channel in self.audioRecorder.channelAssignments)
    {
        NSLog(@"Recorder channel: %@", channel.channelName);
    }*/
    
    AVAudioSessionRouteDescription *currentRoute = [audioSession currentRoute];
    for (AVAudioSessionPortDescription *output in currentRoute.outputs)
    {
        /*for (AVAudioSessionChannelDescription *channel in output.channels)
        {
            //NSLog(@"%@ - channel: %@", [output portType], channel.channelName);
        }*/
        
        if ([[output portType] isEqualToString:AVAudioSessionPortHeadphones])
        {
            self.audioRecorder.channelAssignments = output.channels;
        }
    }
    
    /*for (AVAudioSessionChannelDescription *channel in self.audioRecorder.channelAssignments)
    {
        NSLog(@"Recorder channel: %@", channel.channelName);
    }*/
    
    /*for (AVAudioSessionPortDescription *input in currentRoute.inputs)
    {
        if ([[input portType] isEqualToString:AVAudioSessionPortLineIn])
        {
            [audioSession setPreferredInput:input error:nil];
            
            for (AVAudioSessionChannelDescription *channel in input.channels)
            {
                NSLog(@"%@ - channel: %@", [input portType], channel.channelName);
            }
            audioRecorder.channelAssignments = input.channels;
        }
    }*/
    
	if ([self.audioRecorder prepareToRecord] == YES)
    {
        [audioSession setActive:YES error:nil];
		[self.audioRecorder record];
	}
    
    else
    {
		int errorCode = CFSwapInt32HostToBig ([error code]); 
		NSLog(@"MicrophoneInput.mm: Error -- %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode);
	}
}

- (IBAction)stopRecording
{
	//NSLog(@"MicrophoneInput.mm  Stopping recording");
	[self.audioRecorder stop];
}

- (IBAction)playRecording:(id)sender
{
	NSLog(@"MicrophoneInput.mm  Starting playback");
	// Init audio with playback capability
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setActive: NO error: nil];
	[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [audioSession setActive: YES error: nil];
	
    // recording location
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = paths[0];
	NSURL* url = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"output.caf"]];
    
	//NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/recordTest.caf", [[NSBundle mainBundle] resourcePath]]];
	NSError *error;
	self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    [self.audioPlayer setDelegate:sender];
	self.audioPlayer.numberOfLoops = 0;
	[self.audioPlayer play];
}

- (IBAction)stopPlaying
{
	NSLog(@"MicrophoneInput.mm  Stopping playback");
	[self.audioPlayer stop];
}

@end
