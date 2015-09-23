//
//  messagesTableViewCell.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/21/14.
//
//

#import "messagesTableViewCell.h"

#import "Constants.h"

@implementation messagesTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        // contact label
        self.contactLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, 175.0, 22.0)];
        self.contactLabel.font = GILL_18;
        self.contactLabel.textColor = [UIColor darkTextColor];
        self.contactLabel.text = @"";
        self.contactLabel.textAlignment = NSTextAlignmentLeft;
        
        // date stamp
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(195.0, 13.0, 110.0, 20.0)];
        self.dateLabel.font = GILL_LIGHT_14;
        self.dateLabel.textColor = [UIColor darkTextColor];
        self.dateLabel.text = @"";
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        
        // song info label
        self.messageTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 35.0, 280.0, 67.0)];
        self.messageTextLabel.font = GILL_16;
        self.messageTextLabel.textColor = DARK_BLUE_GRAY;
        self.messageTextLabel.text = @"";
        
        self.messageTextLabel.numberOfLines = 0;
        self.messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        [self addSubview:self.contactLabel];
        [self addSubview:self.dateLabel];
        [self addSubview:self.messageTextLabel];
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
