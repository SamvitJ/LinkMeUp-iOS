//
//  LinkTableViewCell.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/16/14.
//
//

#import "LinkTableViewCell.h"

#import "Constants.h"

@implementation LinkTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        // contact label
        self.contactLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, 13.0, 200.0, 25.0)];
        self.contactLabel.font = GILL_18;
        self.contactLabel.textColor = [UIColor darkTextColor];
        self.contactLabel.text = @"";
        
        // songInfo label
        self.songInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, 37.0, 180.0, 25.0)];
        self.songInfoLabel.font = GILL_16;
        self.songInfoLabel.textColor = [UIColor darkTextColor];
        self.songInfoLabel.text = @"";
        
        // date stamp
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(115.0, 70.0, 110.0, 20.0)];
        self.dateLabel.font = GILL_LIGHT_14;
        self.dateLabel.textColor = [UIColor darkTextColor];
        self.dateLabel.text = @"";
        
        // status label
        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(235.0, 70.0, 60.0, 20.0)];
        self.statusLabel.font = GILL_LIGHT_14;
        self.statusLabel.textColor = [UIColor redColor];
        self.statusLabel.textAlignment = NSTextAlignmentCenter;
        self.statusLabel.text = @"";
        
        [self addSubview:self.contactLabel];
        [self addSubview:self.songInfoLabel];
        [self addSubview:self.dateLabel];
        [self addSubview:self.statusLabel];
    }
    return self;
}

- (void)awakeFromNib
{

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
