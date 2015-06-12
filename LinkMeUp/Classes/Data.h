//
//  Data.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/7/14.
//
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import <AddressBook/AddressBook.h>

#import <ParseFacebookUtils/PFFacebookUtils.h>

#import "Link.h"
#import "FriendRequest.h"

@interface Data : NSObject


// STATE INFORMATION ***********************************************

// me
@property (nonatomic, strong, readonly) PFUser *me;

// search/contacts VC 
@property (nonatomic) BOOL newSong;

// inbox/link/reply VC
@property (nonatomic, strong) Link *selectedLink;

// *****************************************************************


// MESSENGER SONG DATA *********************************************

// song or video
@property (nonatomic) BOOL isSong;

// iTunes search
@property (nonatomic, strong) NSString *userTitle;
@property (nonatomic, strong) NSString *userArtist;

//@property (nonatomic, strong) NSMutableData *songData;
@property (nonatomic, strong) NSString *iTunesTitle;
@property (nonatomic, strong) NSString *iTunesArtist;
@property (nonatomic, strong) NSString *iTunesAlbum;
@property (nonatomic, strong) NSString *iTunesURL;
@property (nonatomic, strong) NSString *iTunesPreviewURL;
@property (nonatomic, strong) NSString *iTunesArt;
@property (nonatomic, strong) NSNumber *iTunesDuration;

// YouTube search
@property (nonatomic, strong) NSString *userSearchTerm;

//@property (nonatomic, strong) NSMutableData *videoData;
@property (nonatomic, strong) NSString *youtubeVideoId;
@property (nonatomic, strong) NSString *youtubeVideoTitle;
@property (nonatomic, strong) NSString *youtubeVideoChannel;
@property (nonatomic, strong) NSString *youtubeVideoThumbnail;
@property (nonatomic, strong) NSNumber *youtubeVideoViews;
@property (nonatomic, strong) NSNumber *youtubeVideoDuration;

// message
@property (nonatomic, strong) NSString *annotation;

// *****************************************************************


// PARSE DATA ******************************************************

// friend requests (sent to me)
@property (nonatomic, strong) NSMutableArray *friendRequests; // FriendRequest
@property (nonatomic, strong) NSMutableArray *requestSenders; // PFUser (sent to me)

// friends (current)
@property (nonatomic, strong) NSMutableArray *myFriends; // PFUser

// friend suggestions
@property (nonatomic) BOOL hasAddressBookAccess;
@property (nonatomic) BOOL isLinkedWithFB;
@property (nonatomic, strong) NSMutableArray *pendingRequests;  // PFUser (sent by me)
@property (nonatomic, strong) NSMutableArray *suggestedFriends; // PFUser

// address book
@property (nonatomic, strong) NSMutableArray *addressBookData;  // NSDictionary
@property (nonatomic, strong) NSMutableArray *nonUserContacts;  // NSDictionary

// recent link recipients
@property (nonatomic, strong) NSMutableArray *recentRecipients;     // NSDictionary

// links
@property (nonatomic, strong) NSMutableArray *receivedLinkData;
@property (nonatomic, strong) NSMutableArray *sentLinkData;

// loading status
@property (nonatomic) BOOL loadedMasterLinks;
@property (nonatomic) BOOL loadedConnections;
@property (nonatomic) BOOL loadedReceivedLinks;
@property (nonatomic) BOOL loadedSentLinks;

// update counters (tab bar badge count)
@property (nonatomic) int receivedRequestUpdates;
@property (nonatomic) int sentRequestUpdates;

@property (nonatomic) int receivedLinkUpdates;
@property (nonatomic) int sentLinkUpdates;

// Notes
// each array entry of receivedLinkData and sentLinkData is an NSMutableDictionary with three fields:
// @"link": Link, @"contacts": PFUser (received) / NSArray of NSDictionary (sent), and @"art": UIImage

// *****************************************************************




// PUBLIC METHODS **************************************************

// new user init
- (void)duplicateMasterLinks;

// data loading methods
- (void)loadAllData;

- (void)updateAddressBookStatus;
- (void)updateLinkWithFacebookStatus;
- (void)loadConnections;

- (void)loadReceivedLinks:(DataUpdatePriority)priority;
- (void)loadSentLinks:(DataUpdatePriority)priority;
    
// convenience method
- (NSMutableDictionary *)receiverDataForUserId:(NSString *)userId inLink:(Link *)link;
- (NSMutableDictionary *)receiverDataForUserId:(NSString *)userId inReceiversData:(NSDictionary *)receiversData;

// local data update methods
- (BOOL)receivedLinkSeen:(Link *)link;
- (BOOL)sentLinkSeen:(Link *)link;
- (void)receiverActionByUserWithId:(NSString *)userId seenOnSentLink:(Link *)link;

- (void)likeLink:(Link *)link;
- (void)loveLink:(Link *)link;

- (void)updateLink:(Link *)link sentToRecipientWithId:(NSString *)recipientId withMessage:(NSDictionary *)message;
// *****************************************************************

@end