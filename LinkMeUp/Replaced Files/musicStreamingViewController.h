//
//  musicStreamingViewController.h
//  echoprint
//
//  Created by Samvit Jain on 6/13/14.
//
//

#import <UIKit/UIKit.h>

#import <MediaPlayer/MediaPlayer.h>
#import "YTPlayerView.h"

#import "Link.h"

#import "replyViewController.h"

@interface musicStreamingViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate, UIScrollViewDelegate>

//@property (nonatomic, strong) IBOutlet YTPlayerView *playerView;

// selected link
@property (nonatomic, strong) Link *selectedLink;
@property (nonatomic) BOOL isSentLink;

// UI elements
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITableView *table;

// associated VCs
@property (nonatomic, strong) replyViewController *replyVC;

@end

