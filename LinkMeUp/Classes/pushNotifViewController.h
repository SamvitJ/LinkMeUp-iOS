//
//  pushNotifViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 6/8/15.
//
//

#import <UIKit/UIKit.h>

#import "Data.h"

@interface pushNotifViewController : UIViewController <UIAlertViewDelegate>

// the shared application data model
@property (nonatomic, weak) Data *sharedData;

// screen presentation timer
@property (nonatomic, strong) NSTimer *didPresentTimer;

// UI elements
@property (weak, nonatomic) IBOutlet UIView *header;
@property (weak, nonatomic) IBOutlet UILabel *lastTextLine;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;

@property (nonatomic, strong) UIImageView *imageView;

@end
