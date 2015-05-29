//
//  MicrophoneInput.h
//  Echoprint
//
//  Created by Brian Whitman on 1/23/11.
//  Copyright 2011 The Echo Nest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MicrophoneInput : UIViewController {
	int recordEncoding;
	enum
	{
		ENC_AAC = 1,
		ENC_ALAC = 2,
		ENC_IMA4 = 3,
		ENC_ILBC = 4,
		ENC_ULAW = 5,
		ENC_PCM = 6,
	} encodingTypes;
}

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;

-(IBAction) startRecording:(id)sender;
-(IBAction) stopRecording;
-(IBAction) playRecording:(id)sender;
-(IBAction) stopPlaying;

@end

