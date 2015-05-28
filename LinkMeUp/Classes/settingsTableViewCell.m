//
//  settingsTableViewCell.m
//  LinkMeUp
//
//  Created by Samvit Jain on 8/16/14.
//
//

#import "settingsTableViewCell.h"

#import "Constants.h"

@implementation settingsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.userInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(125.0f, 10.0f, 180.0f, 40.0f)];
        self.userInfoLabel.font = GILL_18;
        self.userInfoLabel.textColor = BLUE_GRAY;
        self.userInfoLabel.textAlignment = NSTextAlignmentRight;
        self.userInfoLabel.numberOfLines = 1;
        self.userInfoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        
        [self addSubview:self.userInfoLabel];
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
