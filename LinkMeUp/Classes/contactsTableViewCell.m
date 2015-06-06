//
//  contactsTableViewCell.m
//  LinkMeUp
//
//  Created by Samvit Jain on 6/5/15.
//
//

#import "contactsTableViewCell.h"

#import "Constants.h"

@implementation contactsTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        const CGFloat labelTextSize = 24.0;
        // const CGFloat centerOffset = 2.0;
        
        const CGFloat iconSize = 25.0;
        
        // contact label
        self.contactLabel = [[UILabel alloc] initWithFrame:CGRectMake(55.0, (CONTACTS_ROW_HEIGHT - labelTextSize)/2, 200.0, labelTextSize)];
        self.contactLabel.font = GILL_20;
        self.contactLabel.text = @"";
        self.contactLabel.textAlignment = NSTextAlignmentLeft;
        
        // image view
        self.icon = [[UIImageView alloc] initWithFrame:CGRectMake(15.0, (CONTACTS_ROW_HEIGHT - iconSize)/2, iconSize, iconSize)];
        
        // add subviews
        [self addSubview:self.contactLabel];
        [self addSubview:self.icon];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
