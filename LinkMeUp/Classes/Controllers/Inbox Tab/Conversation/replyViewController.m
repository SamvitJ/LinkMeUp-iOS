//
//  replyViewController.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/20/14.
//
//

#import "replyViewController.h"

#import "Constants.h"
#import "messagesTableViewCell.h"

@interface replyViewController ()
{
    BOOL initialOffset;     // YES if animating to allow user to type
    BOOL justPosted;        // YES if just posted message
}

@end

@implementation replyViewController


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

#pragma mark - Receiver data/messages

- (void)setData
{
    self.receiverData = [self.sharedData receiverDataForUserId:(self.isLinkSender ? self.contactId : self.sharedData.me.objectId) inLink:self.sharedData.selectedLink];
    self.messages = [self.receiverData objectForKey:@"messages"];
}

#pragma mark - Scroll view delegate methods

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (initialOffset && !justPosted)
    {
        self.currentMessage.editable = YES;
        [self.currentMessage becomeFirstResponder];
        
        initialOffset = NO;
    }
}

#pragma mark - Text view delegate methods

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        if (self.currentMessage.isFirstResponder)
        {
            [self.currentMessage resignFirstResponder];
        }
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self.replyTable setContentOffset:CGPointMake(0.0f, MESSAGES_ROW_HEIGHT * ([self.messages count] - 1) + (IS_IPHONE_5 ? 0.0f : MESSAGES_ROW_HEIGHT/2.0 - 5.0f)) animated:YES];
    
    if ([textView.text isEqualToString:@"Enter reply here..."])
        textView.text = @"";
    
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self.replyTable setContentOffset:CGPointMake(0.0f, MAX(0.0f, MESSAGES_ROW_HEIGHT * ([self.messages count] - 1) - (IS_IPHONE_5 ? MESSAGES_ROW_HEIGHT : MESSAGES_ROW_HEIGHT/2.0 + 5.0f))) animated:YES];
    
    if ([textView.text isEqualToString:@""])
        textView.text = @"Enter reply here...";
    
    [textView resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        // done editing
        [textView resignFirstResponder];

        // new message contents
        PFUser *me = self.sharedData.me;
        NSString *myId = me.objectId;
        NSString *myName = [Constants nameElseUsername:me];
        NSDate *now = [NSDate date];
        
        NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:myId, myName, now, self.currentMessage.text, nil]
                                                                            forKeys:[NSArray arrayWithObjects:@"identity", @"name", @"time", @"message", nil]];
        
        // clear text view and add labels
        messagesTableViewCell *cell = (messagesTableViewCell *)[self.replyTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.messages count] inSection:0]];
        cell.dateLabel.text = [Constants dateToString: now];
        cell.messageTextLabel.text = self.currentMessage.text;
        
        self.currentMessage.text = @"";
        self.currentMessage.editable = NO;
        
        // local status variable
        justPosted = YES;
        
        // update local copy
        NSString *linkRecipientId = (self.isLinkSender ? self.contactId : me.objectId);
        [self addMessage:message toLink:self.sharedData.selectedLink sentToRecipientWithId:linkRecipientId];
        [self setData];
        
        // update data in Parse
        PFQuery *linkQuery = [Link query];
        [linkQuery includeKey:@"sender"];
        [linkQuery getObjectInBackgroundWithId:self.sharedData.selectedLink.objectId block:^(PFObject *object, NSError *error) {
            if (!error)
            {
                // update server copy
                Link *link = (Link *)object;
                [self addMessage:message toLink:link sentToRecipientWithId:linkRecipientId];
                
                // update local pointers, if applicable
                if ([self.sharedData.selectedLink.objectId isEqualToString:link.objectId])
                {
                    self.sharedData.selectedLink = link;
                    [self setData];
                }
                
                [self.sharedData.selectedLink saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error)
                    {
                        // send push notification to recipient
                        NSString *channel = (self.isLinkSender ? [NSString stringWithFormat:@"user_%@", [self.receiverData objectForKey:@"identity"]] : [NSString stringWithFormat:@"user_%@", self.sharedData.selectedLink.sender.objectId]);
                        
                        NSString *alert = [NSString stringWithFormat:@"New message from %@", [Constants nameElseUsername:me]];;
                        NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:alert, @"Increment", @"message", [NSNumber numberWithBool:!self.isLinkSender], nil]
                                                                                         forKeys:[NSArray arrayWithObjects:@"alert", @"badge", @"type", @"isSender", nil]];
                        
                        PFPush *newMessagePush = [[PFPush alloc] init];
                        [newMessagePush setChannel: channel];
                        [newMessagePush setData:data];
                        [newMessagePush sendPushInBackground];
                    }
                    
                    else
                    {
                        NSLog(@"Error posting message %@ %@", error, [error userInfo]);
                    }
                }];
            }
            
            else
            {
                NSLog(@"Error retrieving link %@ %@", error, [error userInfo]);
            }
        }];

        return NO;
    }
    
    if ([textView.text length] + text.length > MESSAGE_CHAR_LIMIT)
    {
        return NO;
    }
    
    return YES;
}

#pragma mark - receiversData update methods

- (void)addMessage:(NSDictionary *)message toLink:(Link *)link sentToRecipientWithId:(NSString *)recipientId
{
    NSDate *now = [NSDate date];
    
    // if link was sent BY me
    if ([link.sender.objectId isEqualToString:self.sharedData.me.objectId])
    {
        // find receiver data of link recipient
        NSMutableDictionary *receiverData = [self.sharedData receiverDataForUserId:recipientId inLink:link];
        
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
        NSMutableDictionary *receiverData = [self.sharedData receiverDataForUserId:recipientId inLink:link];
        
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

#pragma mark - Swipe gestures

- (IBAction)swipeRight:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UI action methods

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in each section
    return (justPosted ? [self.messages count] + 1 : [self.messages count] + 2);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    
    if (indexPath.row < [self.messages count])
    {
        CellIdentifier = @"Replies";
    }
    
    else if (indexPath.row == [self.messages count])
    {
        if (!justPosted)
            CellIdentifier = @"New Message";
        
        else CellIdentifier = @"Offset";
    }
    
    else //if (indexPath.row == [self.messages count] + 1)
    {
        CellIdentifier = @"Offset";
    }
    
    messagesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[messagesTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.row < [self.messages count])
    {
        cell.contactLabel.text = [self.messages[indexPath.row] objectForKey:@"name"];
        cell.dateLabel.text = [Constants dateToString:[self.messages[indexPath.row] objectForKey:@"time"]];
        
        cell.messageTextLabel.text = [self.messages[indexPath.row] objectForKey:@"message"];
    }
    
    else if (indexPath.row == [self.messages count])
    {
        if (!justPosted)
        {
            cell.contactLabel.text = [NSString stringWithFormat:@"%@", [Constants nameElseUsername:self.sharedData.me]];
            
            if (!self.currentMessage)
            {
                self.currentMessage = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 35.0f, 280.0f, 67.0f)];
                self.currentMessage.backgroundColor = [UIColor clearColor];
                
                self.currentMessage.scrollEnabled = NO;
                self.currentMessage.textAlignment = NSTextAlignmentLeft;
                self.currentMessage.textColor = BLUE_GRAY;
                self.currentMessage.font = GILL_16;
                self.currentMessage.text = @"";
                
                self.currentMessage.returnKeyType = UIReturnKeySend;
                self.currentMessage.enablesReturnKeyAutomatically = YES;
                
                self.currentMessage.delegate = self;
                [cell addSubview:self.currentMessage];
            }
        }
    }
    
    else // if offset cell
    {
        // do nothing
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    UILabel *label = [self createHeaderLabel];

    [view addSubview:label];
    [view setBackgroundColor:SECTION_HEADER_GRAY];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return REPLIES_HEADER_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.messages count])
    {
        return MESSAGES_ROW_HEIGHT;
    }
    
    else if (indexPath.row == [self.messages count])
    {
        if (!justPosted)
            return MESSAGES_ROW_HEIGHT;
        
        else return BOTTOM_OFFSET;
    }
    
    else return BOTTOM_OFFSET;
}

#pragma mark - View controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self){
        // Custom initialization
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // initialize table
    self.replyTable.delegate = self;
    self.replyTable.dataSource = self;
    
    // exit text fields gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    // add back button
    UIButton *backButton = [Constants createBackButtonWithText:@"Link"];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:backButton];
    
    // set header title
    NSString *fullName = (self.isLinkSender ? [self.receiverData objectForKey:@"name"] : [self.sharedData.selectedLink.sender objectForKey:@"name"]);
    self.headerTitle.text = fullName;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!justPosted)
    {
        initialOffset = YES;
        
        // whether setContentOffset will animate table
        BOOL willAnimate = (IS_IPHONE_5 && [self.messages count] == 1 ? NO : YES);
        
        if (willAnimate)
        {
            [self.replyTable setContentOffset:CGPointMake(0.0f, MESSAGES_ROW_HEIGHT * ([self.messages count] - 1) + (IS_IPHONE_5 ? 0.0f : MESSAGES_ROW_HEIGHT/2.0 - 5.0f)) animated:YES];
        }
        
        else
        {
            // allow user to enter message (see scrollViewDidEndScrollingAnimation:)
            self.currentMessage.editable = YES;
            [self.currentMessage becomeFirstResponder];
            
            initialOffset = NO;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    // set delegates to nil
    self.replyTable.delegate = nil;
    self.replyTable.dataSource = nil;
}

#pragma mark - UI helper methods

- (UILabel *)createHeaderLabel
{
    // link info
    NSString *linkTitle = self.sharedData.selectedLink.title;
    NSString *linkAuthor = (self.sharedData.selectedLink.isSong ? self.sharedData.selectedLink.artist : self.sharedData.selectedLink.videoChannel);
    
    // title
    NSString *title = [[linkTitle stringByAppendingString:@" - "] stringByAppendingString:linkAuthor];
    
    // truncate title
    if ([title length] > 35)
    {
        title = [title substringToIndex: MIN([title length] - 3, 35)];
        title = [title stringByAppendingString:@"..."];
    }
    
    // set label text
    NSString *labelText = [NSString stringWithFormat:@"%@", title];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.lineSpacing = 4.0;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 7.0f, self.replyTable.frame.size.width - 20.0f, REPLIES_HEADER_HEIGHT - 10.0f)];
    label.numberOfLines = 2;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSMutableAttributedString *songInfoString = [[NSMutableAttributedString alloc] initWithString: labelText
                                                                                       attributes: @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                                                      NSFontAttributeName: HELV_16,
                                                                                                      NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    [label setAttributedText:songInfoString];
    
    return label;
}

@end
