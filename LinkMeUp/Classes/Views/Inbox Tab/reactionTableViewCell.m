//
//  reactionTableViewCell.m
//  LinkMeUp
//
//  Created by Samvit Jain on 8/18/14.
//
//

#import "reactionTableViewCell.h"

#import "Constants.h"

@implementation reactionTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        // contact label
        self.contactLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 18.0, 175.0, 22.0)];
        self.contactLabel.font = GILL_18;
        self.contactLabel.textColor = [UIColor darkTextColor];
        self.contactLabel.text = @"";
        self.contactLabel.textAlignment = NSTextAlignmentLeft;
        
        // date stamp
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(195.0, 20.0, 110.0, 20.0)];
        self.dateLabel.font = GILL_LIGHT_14;
        self.dateLabel.textColor = [UIColor darkTextColor];
        self.dateLabel.text = @"";
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        
        [self addSubview:self.contactLabel];
        [self addSubview:self.dateLabel];
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
