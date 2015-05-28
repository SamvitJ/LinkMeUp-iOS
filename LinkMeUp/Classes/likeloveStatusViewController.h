//
//  likeloveStatusViewController.h
//  LinkMeUp
//
//  Created by Samvit Jain on 8/18/14.
//
//

#import <UIKit/UIKit.h>

#import "Constants.h"
#import "Data.h"

@interface likeloveStatusViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

// data
@property (nonatomic) ReactionType reaction;
@property (strong, nonatomic) NSArray *reactionData;

// UI elements
@property (weak, nonatomic) IBOutlet UIView *header;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UITableView *table;

@end
