//
//  Link.m
//  LinkMeUp
//
//  Created by Samvit Jain on 6/30/14.
//
//

#import "Link.h"

#import <Parse/PFObject+Subclass.h>

@implementation Link

@dynamic isText;
@dynamic isSong;

//@dynamic songData, videoData;
@dynamic title, art;
@dynamic storeURL, previewURL, artist, album, duration;
@dynamic videoId, videoChannel, videoViews, videoDuration;

@dynamic annotation;

@dynamic sender;
@dynamic receiversData;

@dynamic isMaster;

@dynamic lastReceiverUpdate;
@dynamic lastReceiverUpdateTime;

+ (NSString *)parseClassName
{
    return @"Link";
}

@end
