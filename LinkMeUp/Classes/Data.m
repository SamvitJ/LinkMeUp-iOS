//
//  Data.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/7/14.
//
//

#import "Data.h"

@interface Data()
{
    /*// internal inst. variables ******
     
     // load connections
    int newReceivedRequestUpdates;
    NSMutableArray *newFriendRequests;
    NSMutableArray *newRequestSenders;
     
    int newSentRequestUpdates;
    NSMutableArray *newMyFriends;
     
    NSMutableArray *newPendingRequests;
    
     // load suggestions
    NSMutableArray *newNonUserContacts;
    NSMutableArray *newSuggestedFriends;
     
     // load links
    int newReceivedLinkUpdates;
    NSMutableArray *receivedArtLoaded;
    NSMutableArray *newReceivedLinkData;
     
    int newSentLinkUpdates;
    NSMutableArray *sentArtLoaded;
    NSMutableArray *newSentLinkData;
    // ********************************/
    
    // connections status booleans
    BOOL loadedReceivedRequests;
    BOOL loadedCurrentFriends;
    BOOL loadedPendingRequests;
    
    // BOOL loadedSuggestions;
    
    BOOL loadedAddrBookSuggestions;
    BOOL loadedFacebookSuggestions;
}

// PRIVATE PROPERTIES **********************************************

// users
@property (nonatomic, strong, readwrite) PFUser *me;
@property (nonatomic, strong) PFUser *master;

// friend suggestions
@property (nonatomic, strong) NSMutableArray *facebookFriends;  // NSDictionary<FBGraphUser>

@property (nonatomic, strong) NSArray *addrBookSuggestions;
@property (nonatomic, strong) NSArray *facebookSuggestions;

// update queues
@property (nonatomic, strong) NSMutableArray *recLinkUpdateQueue;
@property (nonatomic, strong) NSMutableArray *sentLinkUpdateQueue;

// *****************************************************************




// PRIVATE METHODS  ************************************************

- (void)loadSuggestions;
- (void)postConnectionsNotification;

- (void)checkLoadStatus:(NSMutableArray *)artLoaded forReceivedLinks:(NSMutableArray *)linkData withUpdates:(int)updates atIndex:(int)index;
- (void)checkLoadStatus:(NSMutableArray *)artLoaded forSentLinks:(NSMutableArray *)linkData withUpdates:(int)updates atIndex:(int)index;
- (void)postAllLinksNotification;

- (DataUpdateState)postStatusForUpdateQueue:(NSMutableArray *)queue;
- (DataUpdateState)resetStatusForUpdateQueue:(NSMutableArray *)queue;

- (NSData *)artDataForLink:(Link *)link withArtURL:(NSURL *)artURL;
- (void)clearCachedArtForLink:(Link *)link;

// *****************************************************************

@end

@implementation Data

#pragma mark - Set up

- (id) init
{
    self = [super init];
    if (self)
    {
        // received friend requests
        self.friendRequests = [[NSMutableArray alloc] init];       // FriendRequest
        self.requestSenders = [[NSMutableArray alloc] init];       // PFUser
        
        // friends
        self.myFriends = [[NSMutableArray alloc] init];            // PFUser
        
        // sent friend requests (pending)
        self.pendingRequests = [[NSMutableArray alloc] init];      // PFUser
        
        // friend suggestions
        self.facebookFriends = [[NSMutableArray alloc] init];      // NSDictionary<FBGraphUser>
        
        self.addrBookSuggestions = [[NSArray alloc] init];         // PFUser
        self.facebookSuggestions = [[NSArray alloc] init];         // PFUser
        
        self.suggestedFriends = [[NSMutableArray alloc] init];     // PFUser
        
        // address book
        self.addressBookData = [[NSMutableArray alloc] init];      // NSDictionary
        self.nonUserContacts = [[NSMutableArray alloc] init];      // NSDictionary
        
        // links
        self.receivedLinkData = [[NSMutableArray alloc] init];     // NSDictionary
        self.sentLinkData = [[NSMutableArray alloc] init];         // NSDictionary
        
        // set all public status booleans
        self.loadedMasterLinks = YES;
        self.loadedAllConnections = YES;
        self.loadedReceivedLinks = YES;
        self.loadedSentLinks = YES;
        
        // initialize update queues
        self.recLinkUpdateQueue = [[NSMutableArray alloc] init];
        self.sentLinkUpdateQueue = [[NSMutableArray alloc] init];
        
        // save current user info
        self.me = [PFUser currentUser];
        
        // initialize state of messenger
        self.newSong = NO;
    }
    
    return self;
}

- (void)duplicateMasterLinks
{
    // initialize status boolean
    self.loadedMasterLinks = NO;
    
    // query for master user
    PFQuery *masterUserQuery = [PFUser query];
    [masterUserQuery getObjectInBackgroundWithId:MASTER_OBJECT_ID block:^(PFObject *object, NSError *error) {
        if (!error)
        {
            // set data model property
            self.master = (PFUser *)object;
            
            // query for master links
            PFQuery *masterLinksQuery = [Link query];
            [masterLinksQuery whereKey:@"sender" equalTo: object];
            [masterLinksQuery whereKey:@"isMaster" equalTo:[NSNumber numberWithBool:YES]];
            [masterLinksQuery orderByAscending:@"createdAt"];
            [masterLinksQuery findObjectsInBackgroundWithBlock:^(NSArray *masterLinks, NSError *error) {
                if (!error)
                {
                    NSMutableArray *masterLinksPosted = [[NSMutableArray alloc] init];
                    
                    // set status
                    for (int i = 0; i < [masterLinks count]; i++)
                        masterLinksPosted[i] = [NSNumber numberWithBool:NO];
                
                    // duplicate, set, post links
                    for (int i = 0; i < [masterLinks count]; i++)
                    {
                        // current link
                        Link *link = masterLinks[i];
                        
                        // initialize my copy
                        Link *myCopy = [[Link alloc] init];
                        
                        // copy existing link data
                        NSArray *keys = [link allKeys];
                        for (NSString *key in keys)
                        {
                            // if key value is not null and if key is not receivers (PFRelation) or isMaster
                            if ([link objectForKey:key] && ![key isEqualToString:@"receivers"] && ![key isEqualToString:@"isMaster"])
                            {
                                [myCopy setObject:[link objectForKey:key] forKey:key];
                            }
                        }
                        
                        //NSLog(@"Original link %@   My Copy %@", link, myCopy);
                        
                        // add sender
                        myCopy.sender = self.master;
                        
                        // set my read/write permissions
                        PFACL *ACL = myCopy.ACL;
                        [ACL setReadAccess:YES forUser:self.me];
                        [ACL setWriteAccess:YES forUser:self.me];
                        myCopy.ACL = ACL;
                        
                        // set receiversData
                        myCopy.receiversData = [[NSMutableArray alloc] init];
                        
                        NSDate *now = [NSDate date];
                        NSString *senderId = myCopy.sender.objectId;
                        NSString *senderName = [Constants nameElseUsername:myCopy.sender];
                        
                        NSMutableDictionary *myData = [[NSMutableDictionary alloc] init];
                        
                        // identity/name
                        myData[@"identity"] = self.me.objectId;
                        myData[@"name"] = [Constants nameElseUsername:self.me];
                        
                        // updated by sender, used by receiver inbox
                        myData[@"lastSenderUpdate"] = [NSNumber numberWithInt:kLastUpdateNewLink];
                        myData[@"lastSenderUpdateTime"] = [NSDate date]; // myCopy.lastReceiverUpdateTime;
                        
                        // updated by receiver, used by sender message table
                        myData[@"seen"] = [NSNumber numberWithBool:NO];
                        myData[@"responded"] = [NSNumber numberWithBool:NO];
                        
                        // updated by receiver, used by both sender/receiver
                        myData[@"liked"] = [NSNumber numberWithBool:NO];
                        myData[@"loved"] = [NSNumber numberWithBool:NO];
                        
                        // first message
                        NSMutableDictionary *firstMessage = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:senderId, senderName, now, myCopy.annotation, nil]
                                                                                                 forKeys:[NSArray arrayWithObjects:@"identity", @"name", @"time", @"message", nil]];
                        myData[@"messages"] = [[NSMutableArray alloc] initWithObjects:firstMessage, nil];
                        
                        // add my data to receiversData
                        [myCopy.receiversData addObject:myData];
                        
                        //NSLog(@"Original link %@   My Copy %@", link, myCopy);
                        
                        // post link
                        [myCopy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (!error)
                            {
                                // add myself as recipient
                                PFRelation *receivers = [myCopy relationForKey:@"receivers"];
                                [receivers addObject:self.me];
                                
                                [myCopy saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                    if (!error)
                                    {
                                        masterLinksPosted[i] = [NSNumber numberWithBool:YES];
                                        [self postMasterLinksNotification:masterLinksPosted];
                                    }
                                    
                                    else
                                    {
                                        NSLog(@"Error saving link %@ %@", error, [error userInfo]);
                                    }
                                }];
                            }
                            
                            else
                            {
                                NSLog(@"Error saving copy of master link %@ %@", error, [error userInfo]);
                            }
                        }];
                    }
                    
                }
                else
                {
                    NSLog(@"Error finding master links %@ %@", error, [error userInfo]);
                }
            }];
        }
    }];
}

- (void)postMasterLinksNotification:(NSMutableArray *)linksPosted
{
    // check if all received art has loaded
    for (int i = 0; i < [linksPosted count]; i++)
    {
        if ([linksPosted[i] boolValue] == NO)
            return;
    }
    
    self.loadedMasterLinks = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"postedMasterLinks" object:nil userInfo:nil];
}



#pragma mark - Accessors

- (void)setSelectedLink:(Link *)selectedLink
{
    _selectedLink = selectedLink;
    
    // post updated link notification
    NSDictionary *linkData = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObject:selectedLink] forKeys:[NSArray arrayWithObject:@"link"]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updatedLink" object:nil userInfo:linkData];
}



#pragma mark - Data loading methods



#pragma mark - Loading all data

- (void)loadAllData
{
    NSLog(@"Now loading data");
    
    [self updateLinkWithFacebookStatus];
    [self updateAddressBookStatus];
    [self loadConnections];
    
    [self loadReceivedLinks: kPriorityLow];
    [self loadSentLinks: kPriorityLow];
}


#pragma mark - Update link with FB status

- (void)updateLinkWithFacebookStatus
{
    self.isLinkedWithFB = [PFFacebookUtils isLinkedWithUser:self.me];
}


#pragma mark - Update address book status

- (void)updateAddressBookStatus
{
    self.hasAddressBookAccess = (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized);
}


#pragma mark - Loading connections

- (void)loadConnections
{
    if (!self.loadedAllConnections)
    {
        NSLog(@"Already loading connections...");
        return;
    }

    // initialize status booleans
    self.loadedAllConnections = NO;
    loadedReceivedRequests = NO;
    loadedCurrentFriends = NO;
    loadedPendingRequests = NO;

    
    
    // initialize temp variables
    __block int newReceivedRequestUpdates = 0;
    __block NSMutableArray *newFriendRequests = [[NSMutableArray alloc] init];
    __block NSMutableArray *newRequestSenders = [[NSMutableArray alloc] init];
    
    // check for received friend requests
    PFQuery *newRequestsQuery = [FriendRequest query];
    [newRequestsQuery whereKey:@"receiver" equalTo:self.me];
    [newRequestsQuery whereKey:@"accepted" equalTo:@NO];
    [newRequestsQuery orderByDescending:@"createdAt"];
    [newRequestsQuery includeKey:@"sender"];
    [newRequestsQuery setLimit: 1000];
    [newRequestsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error)
        {
            // The find succeeded.
            NSLog(@"Successfully retrieved %lu received friend requests.", (unsigned long)[objects count]);
            newFriendRequests = (NSMutableArray *)objects;
            
            // friend request information
            for (int i = 0; i < [newFriendRequests count]; i++)
            {
                FriendRequest *request = newFriendRequests[i];
                
                // request senders
                PFUser *sender = request.sender;
                newRequestSenders[i] = sender;
                
                // no. of (unseen) received friend requests
                if ([[request objectForKey:@"seen"] boolValue] == NO)
                    newReceivedRequestUpdates++;
            }
            
            // update data model
            self.friendRequests = newFriendRequests;
            self.requestSenders = newRequestSenders;
            self.receivedRequestUpdates = newReceivedRequestUpdates;
        }
        
        else
        {
            // Log details of the failure
            NSLog(@"Error loading new friend requests %@ %@", error, [error userInfo]);
        }

        // set status and post notifications
        loadedReceivedRequests = YES;
        [self loadSuggestions];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoadedFriendRequests object:nil userInfo:nil];
    }];
    
    
    
    // initialize temp variable
    __block int newSentRequestUpdates = 0;
    __block NSMutableArray *newMyFriends = [[NSMutableArray alloc] init];
    
    // check for sent friend requests (accepted)
    PFQuery *newFriendsQuery = [FriendRequest query];
    [newFriendsQuery whereKey:@"sender" equalTo:self.me];
    [newFriendsQuery whereKey:@"accepted" equalTo:@YES];
    [newFriendsQuery orderByDescending:@"createdAt"];
    [newFriendsQuery includeKey:@"receiver"];
    [newFriendsQuery setLimit: 1000];
    [newFriendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error)
        {
            // no. of (accepted) sent friend requests
            newSentRequestUpdates = (int)[objects count];
            
            // add recipients of friend request to my friends list
            PFRelation *myFriends = [self.me relationForKey:@"friends"];
            
            for (FriendRequest *request in objects)
            {
                [myFriends addObject:request.receiver];
                [request deleteInBackground];
            }
        }
        
        else
        {
            // Log details of the failure
            NSLog(@"Error loading accepted friend requests %@ %@", error, [error userInfo]);
        }
        
        // load my friends
        [self.me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            PFRelation *myFriends = [self.me relationForKey:@"friends"];
            PFQuery *friendsQuery = [myFriends query];
            [friendsQuery setLimit: 1000];
            [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error)
                {
                    NSLog(@"Successfully retrieved %lu friends.", (unsigned long)[objects count]);
                    newMyFriends = (NSMutableArray *)objects;
                    
                    // update data model
                    self.myFriends = newMyFriends;
                    self.sentRequestUpdates = newSentRequestUpdates;
                }
                
                else
                {
                    // Log details of the failure
                    NSLog(@"Error loading current friends %@ %@", error, [error userInfo]);
                    newMyFriends = [self.me objectForKey:@"friends"]; // cache policy?
                }
                
                // set status and post notifications
                loadedCurrentFriends = YES;
                [self loadSuggestions];
                [[NSNotificationCenter defaultCenter] postNotificationName:kLoadedFriendList object:nil userInfo:nil];
            }];
        }];
    }];
    
    
    
    // initialize temp variable
    __block NSMutableArray *newPendingRequests = [[NSMutableArray alloc] init];
    
    // check for sent friend requests (pending)
    // note: friends tab only shows pending requests from among suggested friends
    PFQuery *pendingRequestsQuery = [FriendRequest query];
    [pendingRequestsQuery whereKey:@"sender" equalTo:self.me];
    [pendingRequestsQuery whereKey:@"accepted" equalTo:@NO];
    [pendingRequestsQuery orderByDescending:@"createdAt"];
    [pendingRequestsQuery includeKey:@"receiver"];
    [pendingRequestsQuery setLimit: 1000];
    [pendingRequestsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error)
        {
            NSLog(@"Successfully retrieved %lu pending, sent friend requests.", (unsigned long)[objects count]);
            
            // recipients of friend requests
            for (int i = 0; i < [objects count]; i++)
            {
                FriendRequest *pending = objects[i];
                newPendingRequests[i] = (pending.receiver ? pending.receiver : [NSNull null]);
            }
            
            // update data model
            self.pendingRequests = newPendingRequests;
        }
        else
        {
            // Log details of the failure
            NSLog(@"Error loading pending, sent friend requests %@ %@", error, [error userInfo]);
        }
        
        // set status and post notifications
        loadedPendingRequests = YES;
        [self loadSuggestions];
    }];
}

- (void)loadSuggestions
{
    // return if not done loading friend requests/current friends
    if (!loadedReceivedRequests || !loadedCurrentFriends || !loadedPendingRequests)
        return;
    
    // otherwise...
    
    // populate recentRecipients
    self.recentRecipients = self.me[@"recentRecipients"];
    
    // initialize local status booleans
    loadedAddrBookSuggestions = NO;
    loadedFacebookSuggestions = NO;
    
    // initialize temp variables
    NSMutableArray *newNonUserContacts = [[NSMutableArray alloc] init];
    
    
    
    // contacts to exclude
    
    // generate array of friendIDs
    NSMutableArray *friendIDs = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.myFriends count]; i++)
    {
        PFUser *myFriend = self.myFriends[i];
        friendIDs[i] = myFriend.objectId;
    }
    
    // generate array of requestIDs
    NSMutableArray *requestIDs = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.requestSenders count]; i++)
    {
        PFUser *potentialFriend = self.requestSenders[i];
        requestIDs[i] = potentialFriend.objectId;
    }
    
    NSArray *excludedIDs = [friendIDs arrayByAddingObjectsFromArray:requestIDs];
    
    
    
    // find LMU users among contacts
    bool couldGetAB = [self saveAddressBookContacts];
    
    if (!couldGetAB)
    {
        NSLog(@"Could not save AB - done loading AB suggestions");
        
        loadedAddrBookSuggestions = YES;
        [self postConnectionsNotification];
    }
    else
    {
        // construct list of all phone numbers in contacts
        NSMutableArray *allPhoneNumbers = [[NSMutableArray alloc] init];
        
        for (NSDictionary *contact in self.addressBookData)
        {
            NSArray *phones = contact[@"phone"];
            
            for (__strong NSString *phone in phones)
            {
                // remove all non-numeric characters
                phone = [Constants removeNonNumericFromPhoneNumber:phone];
                
                // add both variants of phone number (with and without country code)
                [allPhoneNumbers addObjectsFromArray:[Constants allVariantsOfPhoneNumber:phone]];
            }
        }
        
        // query for LMU users with included phone numbers
        PFQuery *query = [PFUser query];
        [query whereKey:@"mobile_number" containedIn: allPhoneNumbers];
        [query whereKey:@"objectId" notContainedIn:excludedIDs]; // slow operation
        [query whereKey:@"objectId" notEqualTo:self.me.objectId];
        [query setLimit: 1000];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error)
            {
                // The find succeeded
                NSLog(@"Successfully retrieved %lu friend suggestions (address book).", (unsigned long)[objects count]);
                self.addrBookSuggestions = objects;
            }
            else
            {
                NSLog(@"Error querying for LMU users among mobile contacts %@ %@", error, [error localizedDescription]);
            }
            
            // populate list of non-user contacts
            NSArray *allUsers = [[self.myFriends arrayByAddingObjectsFromArray:self.requestSenders] arrayByAddingObjectsFromArray:self.addrBookSuggestions];
            
            for (NSDictionary *contact in self.addressBookData)
            {
                // default: not LinkMeUp user
                BOOL isUser = false;
                
                // determine if contact is a LMU user based on mobile number
                NSArray *phoneArray = contact[@"phone"];
                for (__strong NSString *phone in phoneArray)
                {
                    for (PFUser *user in allUsers)
                    {
                        // remove all non-numeric characters
                        phone = [Constants removeNonNumericFromPhoneNumber:phone];
                        
                        NSString *userNumber = user[@"mobile_number"];
                        
                        // if (user phone number not in Parse)...
                        if (!userNumber)
                            continue;
                        
                        // else... check for equality
                        if ([Constants comparePhone1:userNumber withPhone2:phone])
                        {
                            isUser = true;
                            break;
                        }
                    }
                    
                    if (isUser)
                        break;
                }
                
                if (!isUser)
                {
                    // add if phone number (mobile or iPhone) known
                    if ([contact[@"phone"] count])
                        [newNonUserContacts addObject:contact];
                }
            }
            
            // NSLog(@"Non user contacts: %@", newNonUserContacts);
            
            // update data model properties
            self.nonUserContacts = newNonUserContacts;
            
            loadedAddrBookSuggestions = YES;
            [self postConnectionsNotification];
        }];
    }

    
    
    // FB friend suggestions
    if (!self.isLinkedWithFB)
    {
        NSLog(@"Not linked with FB - done loading FB suggestions");
        
        loadedFacebookSuggestions = YES;
        [self postConnectionsNotification];
    }
    else
    {
        NSLog(@"Loading FB friends");

        FBRequest* myFacebookFriends = [FBRequest requestForMyFriends];
        //[FBSession setActiveSession: [PFFacebookUtils session]];
        //[FBSession setActiveSession: [myFacebookFriends session]];
        [myFacebookFriends startWithCompletionHandler: ^(FBRequestConnection *connection, NSDictionary* result, NSError *error) {
            if (!error)
            {
                self.facebookFriends = (NSMutableArray *)[result objectForKey:@"data"];
                // NSLog(@"%@", self.facebookFriends);
                
                // generate array of fbIDs
                NSMutableArray *fbIDs = [[NSMutableArray alloc] init];
                for (int i = 0; i < [self.facebookFriends count]; i++)
                {
                    NSDictionary<FBGraphUser>* FBfriend = self.facebookFriends[i];
                    fbIDs[i] = FBfriend.objectID;
                }
                
                PFQuery *query = [PFUser query];
                [query whereKey:@"facebook_id" containedIn:fbIDs];
                [query whereKey:@"objectId" notContainedIn:excludedIDs];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error)
                    {
                        // The find succeeded.
                        NSLog(@"Successfully retrieved %lu friend suggestions (facebook).", (unsigned long)[objects count]);
                        self.facebookSuggestions = objects;
                    }
                    
                    else
                    {
                        // Log details of the failure
                        NSLog(@"Error loading friend suggestions %@ %@", error, [error userInfo]);
                    }
                    
                    // set status and post notifications
                    loadedFacebookSuggestions = YES;
                    [self postConnectionsNotification];
                }];
            }
            
            else
            {
                NSLog(@"Error loading facebook friends %@ %@", error, [error localizedDescription]);
                
                // set status and post notifications
                loadedFacebookSuggestions = YES;
                [self postConnectionsNotification];
            }
        }];
    }
}

- (void)postConnectionsNotification
{
    if (loadedAddrBookSuggestions && loadedFacebookSuggestions)
    {
        // update data model property
        NSMutableArray *newSuggestedFriends = [[NSMutableArray alloc] initWithArray:self.addrBookSuggestions];
        
        if ([newSuggestedFriends count])
        {
            // add non-duplicate suggestions
            for (PFUser *facebookSuggestion in self.facebookSuggestions)
            {
                bool isContained = false;
                
                for (PFUser *addrBookSuggestion in self.addrBookSuggestions)
                {
                    if ([facebookSuggestion.objectId isEqualToString:addrBookSuggestion.objectId])
                    {
                        NSLog(@"Duplicate %@", addrBookSuggestion);
                        isContained = true;
                        break;
                    }
                }
                
                if (!isContained)
                {
                    [newSuggestedFriends addObject:facebookSuggestion];
                }
            }
        }
        else
        {
            [newSuggestedFriends addObjectsFromArray:self.facebookSuggestions];
        }

        self.suggestedFriends = newSuggestedFriends;
        
        self.loadedAllConnections = YES;
        NSLog(@"Did finish loading connections");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoadedConnections object:nil userInfo:nil];
    }
}

- (bool)saveAddressBookContacts
{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
    
    // return false if no permission or error
    if (!self.hasAddressBookAccess || addressBook == nil)
        return false;
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSArray *ABRcontacts = [(__bridge NSArray *) allPeople copy];
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    
    for (id person in ABRcontacts)
    {
        // name
        NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)(person), kABPersonFirstNameProperty);
        
        if (!firstName)
            firstName = @"";
        
        NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue((__bridge ABRecordRef)(person), kABPersonLastNameProperty);
        
        if (!lastName)
            lastName = @"";
        
        // phone number
        ABMultiValueRef ABRphoneNumbers = ABRecordCopyValue((__bridge ABRecordRef)(person), kABPersonPhoneProperty);
        NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
        
        if (ABMultiValueGetCount(ABRphoneNumbers) > 0)
        {
            long indexCount = ABMultiValueGetCount(ABRphoneNumbers);
            for (long index = 0; index < indexCount; index++)
            {
                CFStringRef CFSRtype = ABMultiValueCopyLabelAtIndex(ABRphoneNumbers, index);
                NSString *type = (__bridge_transfer NSString *)ABAddressBookCopyLocalizedLabel(CFSRtype);
                
                if ([type isEqualToString:@"iPhone"] || [type isEqualToString:@"mobile"])
                {
                    NSString *phone = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(ABRphoneNumbers, index);
                    
                    // remove all non-numeric characters
                    NSCharacterSet *excludedChars = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                    phone = [[phone componentsSeparatedByCharactersInSet: excludedChars] componentsJoinedByString:@""];
                    
                    [phoneNumbers addObject:phone];
                }
                
                CFRelease(CFSRtype);
            }
        }
        
        CFRelease(ABRphoneNumbers);
        
        // email
        ABMultiValueRef ABRemails = ABRecordCopyValue((__bridge ABRecordRef)(person), kABPersonEmailProperty);
        NSMutableArray *emails = [[NSMutableArray alloc] init];
        
        if (ABMultiValueGetCount(ABRemails) > 0)
            emails = (__bridge_transfer NSMutableArray *)ABMultiValueCopyArrayOfAllValues(ABRemails);
        
        CFRelease(ABRemails);
        
        // NSLog(@"Contact %@ %@ %@ %@", firstName, lastName, phoneNumbers, emails);
        
        // add to array
        [contacts addObject:@{@"first_name": firstName,
                              @"name": [[firstName stringByAppendingString:@" "] stringByAppendingString:lastName],
                              @"phone": phoneNumbers,
                              @"email": emails}];
    }
    
    // save locally
    self.addressBookData = contacts;
    
    // save to Parse
    PFUser *me = self.me;
    me[@"address_book"] = contacts;
    
    [me saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error)
        {
            NSLog(@"Error saving address book to Parse %@ %@", error, [error userInfo]);
        }
        else
        {
            // NSLog(@"Address book saved to Parse");
        }
    }];
    
    // return success
    return true;
}


#pragma mark - Loading links

- (void)loadReceivedLinks:(DataUpdatePriority)priority
{
    // queue index
    int myUpdateIndex = (int)[self.recLinkUpdateQueue count];
    
    // add request to queue
    NSMutableDictionary *updateRequest = [@{@"priority": [NSNumber numberWithInt:priority],
                                            @"state": [NSNumber numberWithInt:kStatePending]} mutableCopy];
    [self.recLinkUpdateQueue addObject:updateRequest];
    //NSLog(@"Received link update request %u: %@", myUpdateIndex, updateRequest);
    
    // initialize status booleans
    self.loadedReceivedLinks = NO; // non-empty queue
    NSMutableArray *receivedArtLoaded = [[NSMutableArray alloc] init];
    
    // initialize temp variables
    __block int newReceivedLinkUpdates = 0;
    NSMutableArray *newReceivedLinkData = [[NSMutableArray alloc] init];
    
    // query for received links
    PFQuery *receivedLinksQuery = [Link query];
    [receivedLinksQuery whereKey:@"receivers" equalTo:self.me];
    [receivedLinksQuery includeKey:@"sender"];
    [receivedLinksQuery orderByDescending:@"updatedAt"];
    [receivedLinksQuery setLimit: 1000];
    [receivedLinksQuery findObjectsInBackgroundWithBlock:^(NSArray *parseRecLinks, NSError *error) {
        if (!error)
        {
            NSLog(@"Successfully retrieved %lu received links", (unsigned long)[parseRecLinks count]);
            
            // sort messages by lastUpdated
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"receiversData" ascending:NO comparator:^NSComparisonResult(id obj1, id obj2) {
                
                // determine lastUpdated time for first object
                NSMutableDictionary *myData1 = [self receiverDataForUserId:self.me.objectId inReceiversData:obj1];
                NSDate *date1 = [myData1 objectForKey:@"lastSenderUpdateTime"];
                
                NSMutableDictionary *myData2 = [self receiverDataForUserId:self.me.objectId inReceiversData:obj2];
                NSDate *date2 = [myData2 objectForKey:@"lastSenderUpdateTime"];
                
                // compare times
                return ([date1 compare:date2]);
            }];
            
            // sort received links
            NSArray *sortDescriptors = [NSArray arrayWithObjects: sortDescriptor, nil];
            parseRecLinks = [parseRecLinks sortedArrayUsingDescriptors:sortDescriptors];

            // initialization
            for (int i = 0; i < [parseRecLinks count]; i++)
            {
                receivedArtLoaded[i] = @NO;
                newReceivedLinkData[i] = [[NSMutableDictionary alloc] init];
            }
            
            // load links
            for (int i = 0; i < [parseRecLinks count]; i++)
            {
                // set link
                Link *currentLink = parseRecLinks[i];
                newReceivedLinkData[i][@"link"] = currentLink;
                
                // set seen status
                NSMutableDictionary *receiverData = [self receiverDataForUserId:self.me.objectId inLink:currentLink];
                
                if ([[receiverData objectForKey:@"lastSenderUpdate"] integerValue] != kLastUpdateNoUpdate)
                    newReceivedLinkUpdates++;
           
                // set sender field
                newReceivedLinkData[i][@"contacts"] = (currentLink.sender ? currentLink.sender : @{@"name": @"unknown user"});

                // look for art in old array (N^2)
                for (int j = 0; j < [self.receivedLinkData count]; j++)
                {
                    Link *oldLink = [self.receivedLinkData[j] objectForKey:@"link"];
                    
                    // if link found, use its art
                    if ([currentLink.objectId isEqualToString:oldLink.objectId])
                    {
                        UIImage *oldArt = [self.receivedLinkData[j] objectForKey:@"art"];
                      
                        // if blank image, break
                        if ([oldArt CGImage] == nil)
                            break;
                        
                        // otherwise, set art and break
                        newReceivedLinkData[i][@"art"] = oldArt;
                        receivedArtLoaded[i] = @YES;
                        break;
                    }
                }
                
                // if art not found, load from URL
                if ([receivedArtLoaded[i] isEqual: @NO])
                {
                    NSURL *artURL = [NSURL URLWithString:currentLink.art];

                    // create NSURLSession task
                    NSURLSession *session = [NSURLSession sharedSession];
                    NSURLSessionDataTask *task = [session dataTaskWithURL:artURL
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        
                        /*if (error)
                            NSLog(@"Error loading art for link %@ %@ %@", currentLink, error, [error userInfo]);*/
                                                            
                        // create image
                        UIImage *art = ([UIImage imageWithData:data] ? [UIImage imageWithData:data] : [[UIImage alloc] init]);
                        
                        // set art
                        newReceivedLinkData[i][@"art"] = art;
                        
                        // update status
                        dispatch_async(dispatch_get_main_queue(), ^{
                           
                            receivedArtLoaded[i] = @YES;
                            [self checkLoadStatus:receivedArtLoaded forReceivedLinks:newReceivedLinkData withUpdates:newReceivedLinkUpdates atIndex:myUpdateIndex];
                        });
                    }];
                    
                    // execute task
                    [task resume];
                }
            }
        }
        
        else
        {
            NSLog(@"Error loading received links %@ %@", error, [error userInfo]);
            
            // load from cache
        }
        
        [self checkLoadStatus:receivedArtLoaded forReceivedLinks:newReceivedLinkData withUpdates:newReceivedLinkUpdates atIndex:myUpdateIndex];
    }];
}

- (void)loadSentLinks:(DataUpdatePriority)priority
{
    // queue index
    int myUpdateIndex = (int)[self.sentLinkUpdateQueue count];
    
    // add request to queue
    NSMutableDictionary *updateRequest = [@{@"priority": [NSNumber numberWithInt:priority],
                                            @"state": [NSNumber numberWithInt:kStatePending]} mutableCopy];
    [self.sentLinkUpdateQueue addObject:updateRequest];
    //NSLog(@"Sent link update request %u: %@", myUpdateIndex, updateRequest);
    
    // initalize status booleans
    self.loadedSentLinks = NO; // non-empty queue
    NSMutableArray *sentArtLoaded = [[NSMutableArray alloc] init];

    // initialize temp variables
    __block int newSentLinkUpdates = 0;
    NSMutableArray *newSentLinkData = [[NSMutableArray alloc] init];
    
    // query for sent links
    PFQuery *sentLinksQuery = [Link query];
    [sentLinksQuery whereKey:@"sender" equalTo:self.me];
    [sentLinksQuery orderByDescending:@"lastReceiverUpdateTime"];
    [sentLinksQuery setLimit: 1000];
    [sentLinksQuery findObjectsInBackgroundWithBlock:^(NSArray *parseSentLinks, NSError *error) {
        if (!error)
        {
            NSLog(@"Successfully retrieved %lu sent links", (unsigned long)[parseSentLinks count]);
            
            // initialize arrays
            for (int i = 0; i < [parseSentLinks count]; i++)
            {
                sentArtLoaded[i] = @NO;
                newSentLinkData[i] = [[NSMutableDictionary alloc] init];
            }
            
            // load links
            for (int i = 0; i < [parseSentLinks count]; i++)
            {
                // set link
                Link *currentLink = parseSentLinks[i];
                newSentLinkData[i][@"link"] = currentLink;
                
                // set seen status
                if ([[currentLink objectForKey:@"lastReceiverUpdate"] integerValue] != kLastUpdateNoUpdate)
                    newSentLinkUpdates++;
                
                // set contacts field for inboxVC table view
                NSMutableArray *receivers = [[NSMutableArray alloc] init];
                
                for (NSDictionary *receiverData in currentLink.receiversData)
                {
                    NSDictionary *receiver = @{@"name": [receiverData objectForKey:@"name"],
                                               @"identity": [receiverData objectForKey:@"identity"]};
                    [receivers addObject: receiver];
                }
                
                // if receiver account deleted, or some other error
                if (![receivers count])
                    receivers = [NSMutableArray arrayWithObject:@{@"name": @"unknown user"}];
                
                newSentLinkData[i][@"contacts"] = receivers;
            
                // look for art in old array (N^2)
                for (int j = 0; j < [self.sentLinkData count]; j++)
                {
                    Link *oldLink = [self.sentLinkData[j] objectForKey:@"link"];
                    
                    // if link found, use its art
                    if ([currentLink.objectId isEqualToString:oldLink.objectId])
                    {
                        UIImage *oldArt = [self.sentLinkData[j] objectForKey:@"art"];
                        
                        // if blank image, break
                        if ([oldArt CGImage] == nil)
                            break;
                        
                        // otherwise, set art and break
                        newSentLinkData[i][@"art"] = oldArt;
                        sentArtLoaded[i] = @YES;
                        break;
                    }
                }
                
                // if art not found, load from URL
                if ([sentArtLoaded[i] isEqual: @NO])
                {
                    NSURL *artURL = [NSURL URLWithString:currentLink.art];
                                        
                    // create NSURLSession task
                    NSURLSession *session = [NSURLSession sharedSession];
                    NSURLSessionDataTask *task = [session dataTaskWithURL:artURL
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        
                        /*if (error)
                            NSLog(@"Error loading art for link %@ %@ %@", currentLink, error, [error userInfo]);*/
                        
                        // create image
                        UIImage *art = ([UIImage imageWithData:data] ? [UIImage imageWithData:data] : [[UIImage alloc] init]);
                        
                        // set art
                        newSentLinkData[i][@"art"] = art;
                        
                        // update status
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            sentArtLoaded[i] = @YES;
                            [self checkLoadStatus:sentArtLoaded forSentLinks:newSentLinkData withUpdates:newSentLinkUpdates atIndex:myUpdateIndex];
                        });
                    }];
                    
                    // execute task
                    [task resume];
                }
            }
        }
        
        else
        {
            NSLog(@"Error loading sent links %@ %@", error, [error userInfo]);
            
            // load from cache
        }
        
        [self checkLoadStatus:sentArtLoaded forSentLinks:newSentLinkData withUpdates:newSentLinkUpdates atIndex:myUpdateIndex];
    }];
}

- (void)checkLoadStatus:(NSMutableArray *)artLoaded forReceivedLinks:(NSMutableArray *)linkData withUpdates:(int)updates atIndex:(int)index
{
    // check if all received art has loaded
    for (int i = 0; i < [artLoaded count]; i++)
    {
        if ([artLoaded[i] boolValue] == NO)
            return;
    }
    
    // if so..
    //NSLog(@"Rec: loaded rec links %u", index);
    
    // if other requests are in the queue and I am low priority...
    if ([self.recLinkUpdateQueue count] > 1 && [self.recLinkUpdateQueue[index][@"priority"] integerValue] == kPriorityLow)
    {
        // NSLog(@"Rec: low priority %u", index);
        // set my state as "completed"
        self.recLinkUpdateQueue[index][@"state"] = [NSNumber numberWithInt: kStateCompleted];
    }
    
    // if a later request completed earlier...
    else if ([self.recLinkUpdateQueue[index][@"state"] integerValue] == kStateCancelled)
    {
        // NSLog(@"Rec: cancelled %u", index);
        // set my state as "completed"
        self.recLinkUpdateQueue[index][@"state"] = [NSNumber numberWithInt: kStateCompleted];
    }
    
    // otherwise
    else
    {
        //NSLog(@"Rec: will update %u", index);
        
        // set my state as "completed"
        self.recLinkUpdateQueue[index][@"state"] = [NSNumber numberWithInt: kStateCompleted];
    
        // cancel all earlier pending updates
        for (int i = 0; i < index; i++)
        {
            if ([self.recLinkUpdateQueue[i][@"state"] integerValue] == kStatePending)
                self.recLinkUpdateQueue[i][@"state"] = [NSNumber numberWithInt: kStateCancelled];
        }
        
        // update data
        self.receivedLinkUpdates = updates;
        self.receivedLinkData = linkData;
        
        // queue post state
        DataUpdateState queueState = [self postStatusForUpdateQueue:self.recLinkUpdateQueue];
        if (queueState == kStateCompleted)
        {
            //NSLog(@"Rec: will post notif %u", index);
            
            // post notifications
            self.loadedReceivedLinks = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadedReceivedLinks" object:nil userInfo:nil];
            [self postAllLinksNotification];
        }
    }
    
    // queue reset state
    DataUpdateState queueState = [self resetStatusForUpdateQueue:self.recLinkUpdateQueue];
    if (queueState == kStateCompleted)
    {
        // clear queue
        self.recLinkUpdateQueue = [[NSMutableArray alloc] init];
    }
}

- (void)checkLoadStatus:(NSMutableArray *)artLoaded forSentLinks:(NSMutableArray *)linkData withUpdates:(int)updates atIndex:(int)index
{
    // check if all sent art has loaded
    for (int i = 0; i < [artLoaded count]; i++)
    {
        if ([artLoaded[i] boolValue] == NO)
            return;
    }
    
    // if so...
    //NSLog(@"Sent: loaded sent links %u", index);
    
    // if other requests are in the queue and I am low priority...
    if ([self.sentLinkUpdateQueue count] > 1 && [self.sentLinkUpdateQueue[index][@"priority"] integerValue] == kPriorityLow)
    {
        //NSLog(@"Sent: low priority %u", index);
        // set my state as "completed"
        self.sentLinkUpdateQueue[index][@"state"] = [NSNumber numberWithInt: kStateCompleted];
    }
    
    // if a later request completed earlier...
    else if ([self.sentLinkUpdateQueue[index][@"state"] integerValue] == kStateCancelled)
    {
        //NSLog(@"Sent: cancelled %u", index);
        // set my state as "completed"
        self.sentLinkUpdateQueue[index][@"state"] = [NSNumber numberWithInt: kStateCompleted];
    }
    
    // otherwise
    else
    {
        //NSLog(@"Sent: will update %u", index);
        
        // set my state as "completed"
        self.sentLinkUpdateQueue[index][@"state"] = [NSNumber numberWithInt: kStateCompleted];
        
        // cancel all earlier pending updates
        for (int i = 0; i < index; i++)
        {
            if ([self.sentLinkUpdateQueue[i][@"state"] integerValue] == kStatePending)
                self.sentLinkUpdateQueue[i][@"state"] = [NSNumber numberWithInt: kStateCancelled];
        }
        
        // update data
        self.sentLinkUpdates = updates;
        self.sentLinkData = linkData;
        
        // queue post state
        DataUpdateState queueState = [self postStatusForUpdateQueue:self.sentLinkUpdateQueue];
        if (queueState == kStateCompleted)
        {
            //NSLog(@"Sent: will post notif %u", index);
            
            // post notifications
            self.loadedSentLinks = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadedSentLinks" object:nil userInfo:nil];
            [self postAllLinksNotification];
        }
    }
    
    // queue reset state
    DataUpdateState queueState = [self resetStatusForUpdateQueue:self.sentLinkUpdateQueue];
    if (queueState == kStateCompleted)
    {
        // clear queue
        self.sentLinkUpdateQueue = [[NSMutableArray alloc] init];
    }
}

- (void)postAllLinksNotification
{
    if (self.loadedReceivedLinks && self.loadedSentLinks)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadedAllLinks" object:nil userInfo:nil];
    }
}



#pragma mark - Convenience methods

- (DataUpdateState)postStatusForUpdateQueue:(NSMutableArray *)queue
{
    for (int i = 0; i < [queue count]; i++)
    {
        // if any request pending...
        if ([queue[i][@"state"] integerValue] == kStatePending)
        {
            return kStatePending;
        }
    }
    
    return kStateCompleted;
}

- (DataUpdateState)resetStatusForUpdateQueue:(NSMutableArray *)queue
{
    for (int i = 0; i < [queue count]; i++)
    {
        // if any request pending or cancelled...
        if ([queue[i][@"state"] integerValue] == kStatePending || [queue[i][@"state"] integerValue] == kStateCancelled)
        {
            return kStatePending;
        }
    }
    
    return kStateCompleted;
}

- (NSMutableDictionary *)receiverDataForUserId:(NSString *)userId inLink:(Link *)link
{
    for (NSMutableDictionary *receiverData in link.receiversData)
    {
        if ([[receiverData objectForKey:@"identity"] isEqualToString:userId])
        {
            return receiverData;
        }
    }
    
    return nil;
}

- (NSMutableDictionary *)receiverDataForUserId:(NSString *)userId inReceiversData:(NSDictionary *)receiversData
{
    for (NSMutableDictionary *receiverData in receiversData)
    {
        if ([[receiverData objectForKey:@"identity"] isEqualToString:userId])
        {
            return receiverData;
        }
    }
    
    return nil;
}


#pragma mark - Local data updates

#pragma mark - Seen state updates

- (BOOL)receivedLinkSeen:(Link *)link
{
    // link "seen" status
    NSMutableDictionary *receiverData = [self receiverDataForUserId:self.me.objectId inLink:link];
    NSDate *now = [NSDate date];
    
    // if I haven't seen the last update...
    if ([[receiverData objectForKey:@"lastSenderUpdate"] integerValue] != kLastUpdateNoUpdate)
    {
        // if I haven't seen the link at all, mark it as seen
        if ([[receiverData objectForKey:@"seen"] boolValue] == NO)
        {
            receiverData[@"seen"] = [NSNumber numberWithBool: YES];
            receiverData[@"lastSenderUpdate"] = [NSNumber numberWithInt:kLastUpdateNoUpdate];
            
            // update for sender messages summary table
            receiverData[@"lastReceiverAction"] = [NSNumber numberWithInt:kLastActionSeen];
            receiverData[@"lastReceiverActionTime"] = now;
        }
        
        // if I HAVE seen the link before...
        else
        {
            receiverData[@"lastSenderUpdate"] = [NSNumber numberWithInt:kLastUpdateNoUpdate];
        }
        
        return NO;
    }
    
    // no new update
    else return YES;
    
}

- (BOOL)sentLinkSeen:(Link *)link
{
    // link "seen" status for senders...
    if ([link.lastReceiverUpdate integerValue] != kLastUpdateNoUpdate)
    {
        link.lastReceiverUpdate = [NSNumber numberWithInt:kLastUpdateNoUpdate];
        return NO;
    }
    
    else return YES;
}

- (void)receiverActionByUserWithId:(NSString *)userId seenOnSentLink:(Link *)link
{
    NSMutableDictionary *receiverData = [self receiverDataForUserId:userId inLink:link];
    receiverData[@"lastReceiverActionSeen"] = [NSNumber numberWithBool:YES];
}

#pragma mark - Link like/love

- (void)likeLink:(Link *)link
{
    NSMutableDictionary *receiverData = [self receiverDataForUserId:self.me.objectId inLink:link];
    
    NSDate *now = [NSDate date];
    
    // link not currently "liked"
    if ([[receiverData objectForKey:@"liked"] boolValue] == NO)
    {
        receiverData[@"liked"] = [NSNumber numberWithBool:YES];
        receiverData[@"timeLiked"] = now;
        
        // if previously "loved", demote status but do not tell sender
        if ([[receiverData objectForKey:@"loved"] boolValue] == YES)
        {
            receiverData[@"loved"] = [NSNumber numberWithBool:NO];
        }
        
        else // tell sender!
        {
            // update status for sender
            link.lastReceiverUpdate = [NSNumber numberWithInt:kLastUpdateNewLike];
            link.lastReceiverUpdateTime = now;
            
            // update for sender's messages summary table
            receiverData[@"lastReceiverAction"] = [NSNumber numberWithInt:kLastActionLiked];
            receiverData[@"lastReceiverActionTime"] = now;
            receiverData[@"lastReceiverActionSeen"] = [NSNumber numberWithBool:NO];
        }
    }
    
    // link currently "liked"
    else
    {
        // demote staus but do not tell sender
        receiverData[@"liked"] = [NSNumber numberWithBool:NO];
    }
}

- (void)loveLink:(Link *)link
{
    NSMutableDictionary *receiverData = [self receiverDataForUserId:self.me.objectId inLink:link];
    
    NSDate *now = [NSDate date];
    
    // link not currently "loved"
    if ([[receiverData objectForKey:@"loved"] boolValue] == NO)
    {
        receiverData[@"loved"] = [NSNumber numberWithBool:YES];
        receiverData[@"timeLoved"] = now;
        
        // if previously "liked", promote status!
        if ([[receiverData objectForKey:@"liked"] boolValue] == YES)
        {
            // link no longer just "liked"
            receiverData[@"liked"] = [NSNumber numberWithBool:NO];
        }
        
        // update status for sender
        link.lastReceiverUpdate = [NSNumber numberWithInt:kLastUpdateNewLove];
        link.lastReceiverUpdateTime = now;
        
        // update for sender's messages summary table
        receiverData[@"lastReceiverAction"] = [NSNumber numberWithInt:kLastActionLoved];
        receiverData[@"lastReceiverActionTime"] = now;
        receiverData[@"lastReceiverActionSeen"] = [NSNumber numberWithBool:NO];
    }
    
    // link currently "loved"
    else
    {
        // demote status but do not tell sender
        receiverData[@"loved"] = [NSNumber numberWithBool:NO];
    }
}

#pragma mark - Link messages

- (void)updateLink:(Link *)link sentToRecipientWithId:(NSString *)recipientId withMessage:(NSDictionary *)message
{
    NSDate *now = [NSDate date];
    
    // if link was sent BY me
    if ([link.sender.objectId isEqualToString:self.me.objectId])
    {
        // find receiver data of link recipient
        NSMutableDictionary *receiverData = [self receiverDataForUserId:recipientId inLink:link];
        
        // update status for receiver
        receiverData[@"lastSenderUpdate"] = [NSNumber numberWithInt:kLastUpdateNewMessage];
        receiverData[@"lastSenderUpdateTime"] = now;
        
        // update for my summary table
        receiverData[@"lastReceiverAction"] = [NSNumber numberWithInt:kLastActionNoAction];
        
        // add new message to array
        [[receiverData objectForKey:@"messages"] addObject:message];
    }
    
    else // link sent TO me
    {
        // update status for sender
        link.lastReceiverUpdate = [NSNumber numberWithInt:kLastUpdateNewMessage];
        link.lastReceiverUpdateTime = now;
        
        // find my receiver data
        NSMutableDictionary *receiverData = [self receiverDataForUserId:recipientId inLink:link];
        
        // if I hadn't yet responded, set responded to YES
        if ([[receiverData objectForKey:@"responded"] boolValue] == NO)
        {
            receiverData[@"responded"] = [NSNumber numberWithBool:YES];
        }
        
        // update for sender's messages summary table
        receiverData[@"lastReceiverAction"] = [NSNumber numberWithInt:kLastActionResponded];
        receiverData[@"lastReceiverActionTime"] = now;
        receiverData[@"lastReceiverActionSeen"] = [NSNumber numberWithBool:NO];
        
        // add new message to array
        [[receiverData objectForKey:@"messages"] addObject:message];
    }
}





#pragma mark - Data caching

- (void)createDefaultConfigObject
{
    NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    /* Configure caching behavior for the default session.
     Note that iOS requires the cache path to be a path relative
     to the ~/Library/Caches directory */
    NSString *cachePath = @"/MyCacheDirectory";
    
    NSArray *myPathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *myPath    = [myPathList  objectAtIndex:0];
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    NSString *fullCachePath = [[myPath stringByAppendingPathComponent:bundleIdentifier] stringByAppendingPathComponent:cachePath];
    NSLog(@"Cache path: %@\n", fullCachePath);
    
    NSURLCache *myCache = [[NSURLCache alloc] initWithMemoryCapacity: 16384 diskCapacity: 268435456 diskPath: cachePath];
    defaultConfig.URLCache = myCache;
    defaultConfig.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
}

// retrieves cached art for link if available, else loads from web URL and caches (synchronous)
- (NSData *)artDataForLink:(Link *)link withArtURL:(NSURL *)artURL
{
    // NSString *filePath = [[self applicationCachesDirectory] stringByAppendingPathComponent:fileName];

    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [NSString pathWithComponents:[NSArray arrayWithObjects:dir, self.me.objectId, [NSString stringWithFormat:@"%@.png", link.objectId], nil]];
    
    NSLog(@"%@", path);
    
    NSData *artData;
    
    // if file exists in cache
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        artData = [NSData dataWithContentsOfFile:path];
    }
    
    // else retreive from web and cache locally
    else
    {
        artData = [NSData dataWithContentsOfURL:artURL];
        [artData writeToFile:path atomically:NO];
    }
    
    return artData;
}

- (void)clearCachedArtForLink:(Link *)link
{
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [NSString pathWithComponents:[NSArray arrayWithObjects:dir, self.me.objectId, [NSString stringWithFormat:@"%@.png", link.objectId], nil]];
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    
    if (error)
    {
        NSLog(@"Error removing art from cache %@ %@", error, [error userInfo]);
    }
}

@end
