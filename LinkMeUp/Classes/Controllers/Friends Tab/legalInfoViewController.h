//
//  legalInfoViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 9/2/14.
//
//

#import <UIKit/UIKit.h>

#import "Constants.h"

@interface legalInfoViewController : UIViewController

// UI elements
@property (weak, nonatomic) IBOutlet UIView *header;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UITextView *legalText;

// UI states
@property (nonatomic) LegalInfoType legalInfo;

// Parent view controller
@property (nonatomic) BOOL wasPushed;   // YES implies settings VC pushed me;
                                        //  NO implies signUp VC presented me

@end
