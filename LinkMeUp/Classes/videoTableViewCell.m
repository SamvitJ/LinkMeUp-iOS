//
//  videoTableViewCell.m
//  LinkMeUp
//
//  Created by Samvit Jain on 8/2/14.
//
//

#import "videoTableViewCell.h"

#import "Constants.h"

@implementation videoTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 150.0f, 180.0f, 40.0f)];
        self.titleLabel.font = GILL_14;
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        self.channelLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 190.0f, 95.0f, 15.0f)];
        self.channelLabel.font = GILL_12;
        self.channelLabel.textColor = DARK_BLUE_GRAY;
        self.channelLabel.textAlignment = NSTextAlignmentLeft;
        self.channelLabel.numberOfLines = 0;
        self.channelLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        self.viewsLabel = [[UILabel alloc] initWithFrame:CGRectMake(108.0f, 191.0f, 82.0f, 15.0f)];
        self.viewsLabel.font = GILL_10;
        self.viewsLabel.textColor = BLUE_GRAY;
        self.viewsLabel.textAlignment = NSTextAlignmentRight;
        self.viewsLabel.numberOfLines = 0;
        self.viewsLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        [self addSubview: self.titleLabel];
        [self addSubview: self.channelLabel];
        [self addSubview: self.viewsLabel];
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
