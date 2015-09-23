//
//  Constants.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/2/14.
//
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>





#pragma mark - Devices


// HARDWARE -----------------------------------------------------------------

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)

// requires launch screen xib file
// #define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
// #define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

//----------------------------------------------------------------------------


// SOFTWARE  -----------------------------------------------------------------

#define IS_IOS8 (UIDevice.currentDevice.systemVersion.floatValue >= 8.f)

//----------------------------------------------------------------------------





#pragma mark - Global settings


// MASTER USER ---------------------------------------------------------------

#define MASTER_OBJECT_ID @"ZEQEIkpgPV"

//----------------------------------------------------------------------------

// SETTINGS ------------------------------------------------------------------

// **** app permissions ****
#define PUSH_REQUESTS_LIMIT 10      // max number of push notif (PN) permission requests
#define AB_REQUESTS_LIMIT 10        // max number of address book (AB) permission requests

// **** searchResultsVC ****
#define VEVO_MAX_RESULTS 10
#define SYND_MAX_RESULTS (IS_IPHONE_5 ? 15 : 10)

// **** contactsVC ****
#define NUMBER_RECENTS 8            // max number of contacts in "Recents" table section
#define MANY_LMU_CONTACTS 10        // separate "LMU Users" table section if < MANY_LMU_CONTACTS
#define SEVERAL_RECENTS 4           // [UNUSED] App Store link appended to message if >= SEVERAL_RECENTS

//----------------------------------------------------------------------------

// API KEYS ------------------------------------------------------------------

#define PARSE_PROD_APP_ID @""
#define PARSE_PROD_CLIENT_KEY @""

#define PARSE_DEV_APP_ID @""
#define PARSE_DEV_CLIENT_KEY @""

#define YOUTUBE_API_KEY @""
#define YOUTUBE_CLIENT_ID @""

//----------------------------------------------------------------------------





#pragma mark - Colors


// COLORS --------------------------------------------------------------------

// **** logo ****
#define LIGHT_TURQ [UIColor colorWithHue:(157.0/360.0) saturation:0.27 brightness:1.00 alpha:1.00]

// **** background ****
#define TURQ [UIColor colorWithHue:(194.0/360.0) saturation:0.73 brightness:0.50 alpha:1.00]

// **** headers ****
#define LIME [UIColor colorWithHue:(84.0/360.0) saturation:1.00 brightness:0.68 alpha:1.00]
#define PURPLE [UIColor colorWithHue:(275.0/360.0) saturation:0.93 brightness:0.58 alpha:1.00]
#define MAROON [UIColor colorWithHue:(348.0/360.0) saturation:1.00 brightness:0.53 alpha:1.00]
#define FADED_BLUE [UIColor colorWithHue:(212.0/360.0) saturation:0.44 brightness:0.37 alpha:1.00]

// **** header label ****
#define WHITE_LIME [UIColor colorWithHue:(90.0/360.0) saturation:0.09 brightness:1.00 alpha:1.00]

// **** text ***
#define DARK_BLUE_GRAY [UIColor colorWithHue:(214.0/360.0) saturation:0.22 brightness:0.26 alpha:1.00]
#define BLUE_GRAY [UIColor colorWithHue:(214.0/360.0) saturation:0.22 brightness:0.46 alpha:1.00]
#define HYPERLINK_BLUE [UIColor colorWithHue:(208.0/360.0) saturation:1.00 brightness:0.40 alpha:1.00]

#define DEEP_RED [UIColor colorWithHue:(0.0/360.0) saturation:1.00 brightness:0.60 alpha:1.00] // link loved
#define MILD_AQUA [UIColor colorWithHue:(185.0/360.0) saturation:1.00 brightness:0.50 alpha:1.00] // link liked
#define DEEP_PURPLE [UIColor colorWithHue:(250.0/360.0) saturation:1.00 brightness:0.35 alpha:1.00] // new message

// **** selection ***
#define BRIGHT_GREEN [UIColor colorWithHue:(90.0/360.0) saturation:1.00 brightness:0.85 alpha:1.00] // video results

// **** section header gray ****
#define SECTION_HEADER_GRAY [UIColor colorWithRed:166/255.0 green:177/255.0 blue:186/255.0 alpha:1.0]

// **** messenger tab ****
#define BLUE_200_FAINT [UIColor colorWithHue:(200.0f/360.0f) saturation:0.10 brightness:0.90 alpha:1.0]
#define SAND_50_FAINT [UIColor colorWithHue:(50.0f/360.0f) saturation:0.10 brightness:0.90 alpha:1.0]

#define BLUE_200_LIGHT [UIColor colorWithHue:(200.0f/360.0f) saturation:0.20 brightness:0.75 alpha:1.0]
#define SAND_50_LIGHT [UIColor colorWithHue:(50.0f/360.0f) saturation:0.20 brightness:0.80 alpha:1.0]

#define BLUE_200 [UIColor colorWithHue:(200.0f/360.0f) saturation:0.25 brightness:0.75 alpha:1.0]
#define SAND_50 [UIColor colorWithHue:(50.0f/360.0f) saturation:0.25 brightness:0.80 alpha:1.0]

// **** links and friend states ****
#define FAINT_BLUE [UIColor colorWithRed:0.85 green:0.93 blue:0.98 alpha:1.0]
#define FAINT_GREEN [UIColor colorWithRed:0.85 green:0.98 blue:0.93 alpha:1.0]
#define FAINT_GRAY [UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1.0]
#define FAINT_PURPLE [UIColor colorWithRed:0.98 green:0.85 blue:0.98 alpha:1.0]

// **** friend request buttons ****
#define DARK_BROWN [UIColor colorWithRed:84.0f/255.0f green:57.0f/255.0f blue:45.0f/255.0f alpha:1.0f]
#define TITLE_SHADOW [UIColor colorWithRed:232.0f/255.0f green:203.0f/255.0f blue:168.0f/255.0f alpha:1.0f]
//----------------------------------------------------------------------------





#pragma mark - Fonts


// FONTS ---------------------------------------------------------------------

// **** Gill Sans ****
#define GILL_20 [UIFont fontWithName:@"GillSans" size:20.0]
#define GILL_LIGHT_20 [UIFont fontWithName:@"GillSans-Light" size:20.0]

#define GILL_19 [UIFont fontWithName:@"GillSans" size:19.0]

#define GILL_18 [UIFont fontWithName:@"GillSans" size:18.0]
#define GILL_LIGHT_ITAL_18 [UIFont fontWithName:@"GillSans-LightItalic" size:18.0]

#define GILL_17 [UIFont fontWithName:@"GillSans" size:17.0]

#define GILL_16 [UIFont fontWithName:@"GillSans" size:16.0]
#define GILL_LIGHT_16 [UIFont fontWithName:@"GillSans-Light" size:16.0]

#define GILL_14 [UIFont fontWithName:@"GillSans" size:14.0]
#define GILL_LIGHT_14 [UIFont fontWithName:@"GillSans-Light" size:14.0]

#define GILL_12 [UIFont fontWithName:@"GillSans" size:12.0]

#define GILL_10 [UIFont fontWithName:@"GillSans" size:10.0]

// **** Helvetica Neue ****
#define HELV_32 [UIFont fontWithName:@"HelveticaNeue" size:32.0]
#define HELV_THIN_ITAL_32 [UIFont fontWithName:@"HelveticaNeue-ThinItalic" size:32.0]

#define HELV_24 [UIFont fontWithName:@"HelveticaNeue" size:24.0]

#define HELV_22 [UIFont fontWithName:@"HelveticaNeue" size:22.0]
#define HELV_LIGHT_22 [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0]

#define HELV_BOLD_20 [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0]
#define HELV_20 [UIFont fontWithName:@"HelveticaNeue" size:20.0]
#define HELV_LIGHT_20 [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0]

#define HELV_BOLD_18 [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0]
#define HELV_18 [UIFont fontWithName:@"HelveticaNeue" size:18.0]
#define HELV_LIGHT_18 [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0]

#define HELV_16 [UIFont fontWithName:@"HelveticaNeue" size:16.0]

#define HELV_15 [UIFont fontWithName:@"HelveticaNeue" size:15.0]

#define HELV_14 [UIFont fontWithName:@"HelveticaNeue" size:14.0]
#define HELV_LIGHT_14 [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0]

#define HELV_12 [UIFont fontWithName:@"HelveticaNeue" size:12.0]
#define HELV_LIGHT_12 [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0]

#define HELV_10 [UIFont fontWithName:@"HelveticaNeue" size:10.0]

// **** ChalkboardSE ****
#define CHALK_19 [UIFont fontWithName:@"ChalkboardSE-Regular" size:19.0]
#define CHALK_LIGHT_19 [UIFont fontWithName:@"ChalkboardSE-Light" size:19.0]

#define CHALK_18 [UIFont fontWithName:@"ChalkboardSE-Regular" size:18.0]
//----------------------------------------------------------------------------





#pragma mark - Numeric constants


// NUMBERS -------------------------------------------------------------------

// **** friends VC ****
#define FRIENDS_HEADER_HEIGHT 28.0
#define CONTACTS_ROW_HEIGHT 67.0

// **** search VC ****
#define AUTOCOMPLETE_ROW_HEIGHT (IS_IPHONE_5 ? 36.5 : 33.0)

// **** contacts VC ****
#define CHECKBOX_SIZE 30.0

// **** inbox VC ****
#define LINKS_ROW_HEIGHT 100.0

// **** link VC ****
#define SONG_HEADER_HEIGHT 55.0
#define YOUTUBE_LINK_ROW_HEIGHT 195.0
#define ITUNES_INFO_HEIGHT 50.0

// **** link/reply VC ****
#define MESSAGES_ROW_HEIGHT 105.0

// **** reply VC ****
#define REPLIES_HEADER_HEIGHT 30.0
#define BOTTOM_OFFSET 165.0

// **** likelove VC ****
#define REACTION_ROW_HEIGHT 60.0

// **** button states ****
#define ALPHA_DISABLED 0.439216
#define ALPHA_BACKGROUND 0.35

// **** text char limits ****
#define ANNOTATION_CHAR_LIMIT 75
#define MESSAGE_CHAR_LIMIT 115
//----------------------------------------------------------------------------


// MATH CONSTS ---------------------------------------------------------------

extern const CGFloat k90DegreesClockwiseAngle;
extern const CGFloat k90DegreesCounterClockwiseAngle;

//----------------------------------------------------------------------------


// PHONE NUMBERS -------------------------------------------------------------

extern const NSInteger kPhoneLengthSansUSCountryCode; // phone # length w/o U.S. country code

//----------------------------------------------------------------------------





#pragma mark - String constants


// UNICODE -------------------------------------------------------------------

#define UNICODE_WATCH [NSString stringWithFormat:@"\u231A"]
#define UNICODE_LINK [NSString stringWithFormat:@"\u260A"]

//----------------------------------------------------------------------------


// NOTIFICATION NAMES --------------------------------------------------------

// *** permissions ***
extern NSString *const kDidRegisterForPush;
extern NSString *const kDidFailToRegisterForPush;

extern NSString *const kUserRespondedToPushNotifAlertView;

// *** data load ***
extern NSString *const kLoadedFriendRequests;
extern NSString *const kLoadedFriendList;
extern NSString *const kLoadedConnections;

//----------------------------------------------------------------------------


// STANDARD USER DEFAULTS ----------------------------------------------------

// *** permissions ***
extern NSString *const kDidAttemptToRegisterForPushNotif;
extern NSString *const kDidPresentPushNotifAlertView;

extern NSString *const kDidShowPushVCThisSession;

extern NSString *const kDidEnterFriendsVC;

// *** account creation ***
extern NSString *const kDidNotLaunchNewAccount;
extern NSString *const kDidNotVerifyNumber;
extern NSString *const kDidCreateAccountWithSameEmail;

//----------------------------------------------------------------------------


// DICTIONARY KEYS -----------------------------------------------------------

// *** PFUser ***
extern NSString *const kNumberPushRequests;
extern NSString *const kNumberABRequests;

extern NSString *const kHasAddrBookAccess;

extern NSString *const kRecentRecipients;       // unused
extern NSString *const kAddressBook;            // unused

// *** contactAndState (contactsVC) ***
extern NSString *const kContact;                // unused
extern NSString *const kIsUser;                 // unused
extern NSString *const kSelected;               // unused

//----------------------------------------------------------------------------





#pragma mark - Enums


// app delegate
typedef enum ApplicationLaunch : NSUInteger
{
    kApplicationLaunchNew = 0,
    kApplicationLaunchReturning = 1
} ApplicationLaunch;

typedef enum TabBarIcon : NSUInteger
{
    kTabBarIconInbox = 0,
    kTabBarIconMessenger = 1,
    kTabBarIconFriends = 2
} TabBarIcon;

typedef enum SessionLoginStatus: BOOL
{
    kSessionLoginStatusLoggedOut = 0,
    kSessionLoginStatusLoggedIn = 1,
} SessionLoginStatus;


// data model
typedef enum DataUpdatePriority : NSUInteger
{
    kPriorityLow = 0,
    kPriorityHigh = 1
} DataUpdatePriority;

typedef enum DateUpdateState: NSUInteger
{
    kStatePending = 0,
    kStateCompleted = 1,
    kStateCancelled = 2
} DataUpdateState;


// messenger VC
typedef enum MessengerOptions : NSUInteger
{
    kSendSong = 0,
    kSendVideo = 1
} MessengerOptions;

typedef enum RecipientList : BOOL
{
    kListRemove = 0,
    kListAdd = 1
} RecipientList;


// inbox VC
typedef enum InboxSegments : NSUInteger
{
    kInboxReceived = 0,
    kInboxSent = 1,
    //kInboxStarred = 2
} InboxSegments;


// link VC
typedef enum LinkSections : NSUInteger
{
    kLinkYoutube = 0,
    kLinkMessages = 1
} LinkSections;

typedef enum LastUpdateType : NSUInteger
{
    kLastUpdateNoUpdate = 0,
    kLastUpdateNewLink = 1,
    kLastUpdateNewMessage = 2,
    kLastUpdateNewLove = 3,
    kLastUpdateNewLike = 4
} LastUpdateType;

typedef enum LastActionType : NSUInteger
{
    kLastActionNoAction = 0,
    kLastActionSeen = 1,
    kLastActionLiked = 2,
    kLastActionLoved = 3,
    kLastActionResponded = 4
} LastActionType;


// likelove VC
typedef enum ReactionType: NSUInteger
{
    kReactionLike = 0,
    kReactionLove = 1
} ReactionType;


// friends VC
typedef enum FriendsSegments : NSUInteger
{
    kFriendsRequests = 0,
    kFriendsSuggestions = 1,
    kFriendsCurrent = 2
} FriendsSegments;

typedef enum SearchResultsType: NSUInteger
{
    kSearchResultsRequests = 0,
    kSearchResultsFriends = 1,
    kSearchResultsSuggestions = 2,
    kSearchResultsNew = 3
} SearchResultsType;

// legal info VC
typedef enum LegalInfoType : NSUInteger
{
    kLegalInfoTerms = 0,
    kLegalInfoPrivacy = 1,
    kLegalInfoCredits = 2
} LegalInfoType;


// other
typedef enum Direction: NSUInteger
{
    kDirectionUp = 0,
    kDirectionDown = 1
} Direction;

//----------------------------------------------------------------------------





#pragma mark - Miscellaneous


// CHAR SETS -----------------------------------------------------------------

#define MOBILE_SET [NSCharacterSet characterSetWithCharactersInString:@"0123456789+ (-)*#.,\n"]
#define MOBILE_PUNCT_SET [NSCharacterSet characterSetWithCharactersInString:@" (-)*#.,\n"]
#define CODE_SET [NSCharacterSet characterSetWithCharactersInString:@"0123456789\n"]

#define DIGITS_SET [NSCharacterSet characterSetWithCharactersInString:@"0123456789"]

//----------------------------------------------------------------------------





#pragma mark - Interface


@interface Constants : NSObject

// converts NSString to URL encoded NSString
+ (NSString *)urlEncodeString:(NSString *)string;

// converts an NSDate to an NSString
+ (NSString *)dateToString:(NSDate *)date;

// convert ISO8601 format date/time string to float seconds
+ (NSNumber *)ISO8601FormatToFloatSeconds:(NSString *)duration;

// returns comma-separated string representation of array objects
+ (NSString *)stringForArray:(NSArray *)array withKey:(NSString *)key;



// returns name of user if not null; else returns username
+ (NSString *)nameElseUsername:(PFUser *)user;



// remove all characters besides digits (0-9) and + sign from phone number
+ (NSString *)sanitizePhoneNumber:(NSString *)phone;

// return array containing all applicable variants of phone number (with and without U.S. country code)
+ (NSArray *)allVariantsOfContactNumber:(NSString *)contactNumber; /*givenUserNumber:(NSString *)userNumber;*/

// returns true if phone numbers are equal, else return false
+ (BOOL)comparePhone1:(NSString *)phone1 withPhone2:(NSString *)phone2;



// create LinkMeUp logo label
+ (UILabel *)createLogoLabel;



// create back button with default text "Back"
+ (UIButton *)createBackButton;

// create back button with custom text
+ (UIButton *)createBackButtonWithText:(NSString *)text;

// button states
+ (void)enableButton:(UIButton *)button;
+ (void)disableButton:(UIButton *)button;

+ (void)highlightButton:(UIButton *)button;
+ (void)fadeButton:(UIButton *)button;



// recolor icon image
+ (UIImage *)renderImage:(UIImage *)image inColor:(UIColor *)color;

// add a foreground image to background image
+ (UIImage *)drawImage:(UIImage*)fgImage inImage:(UIImage*)bgImage atPoint:(CGPoint) point;

@end
