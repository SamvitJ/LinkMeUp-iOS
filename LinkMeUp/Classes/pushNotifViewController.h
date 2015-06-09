//
//  pushNotifViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 6/8/15.
//
//

#import <UIKit/UIKit.h>

@interface pushNotifViewController : UIViewController

@property (nonatomic, strong) UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIView *header;
@property (weak, nonatomic) IBOutlet UILabel *lastTextLine;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;

@end
