//
//  linkViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/22/14.
//
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "Link.h"

#import "replyViewController.h"

@interface linkViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

//@property (nonatomic, strong) IBOutlet YTPlayerView *playerView;

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// UI elements
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *header;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIWebView *webView;

@property (strong, nonatomic) UIButton *previewButton;
@property (strong, nonatomic) UIActivityIndicatorView *loadingIndicator;
@property (strong, nonatomic) AVPlayer *songPlayer;

// associated VCs
@property (nonatomic, strong) replyViewController *replyVC;

// UIGraphics helper methods
- (UIButton *)toolbarButtonWithNormalIcon:(UIImage *)normalIcon selectedIcon:(UIImage *)selectedIcon text:(NSString *)text action:(SEL)selector;

@end

