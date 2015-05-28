//
//  Link.h
//  LinkMeUp
//
//  Created by Samvit Jain on 6/30/14.
//
//

#import "Constants.h"
#import <Parse/Parse.h>

@interface Link : PFObject <PFSubclassing>

// song or video?
@property (nonatomic) BOOL isSong;

//@property (nonatomic, strong) NSDictionary *songData;
//@property (nonatomic, strong) NSDictionary *videoData;

// shared song/video data
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *art;

// iTunes song data
@property (nonatomic, strong) NSString *storeURL;
@property (nonatomic, strong) NSString *previewURL;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *album;
@property (nonatomic, strong) NSNumber *duration;

// youtube video data
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *videoChannel;
@property (nonatomic, strong) NSNumber *videoViews;
@property (nonatomic, strong) NSNumber *videoDuration;

// message
@property (nonatomic, strong) NSString *annotation;

// sender/receivers
@property (nonatomic, strong) PFUser *sender;
@property (nonatomic, strong) NSMutableArray *receiversData;

// master links
@property (nonatomic) BOOL isMaster;

// used by sender inbox to display links
// set by receivers of links
@property (nonatomic) NSNumber *lastReceiverUpdate;
@property (nonatomic, strong) NSDate *lastReceiverUpdateTime;

@end
