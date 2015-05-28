//
//  YouTubeSearchBar.m
//  LinkMeUp
//
//  Created by Samvit Jain on 8/6/14.
//
//

#import "YouTubeSearchBar.h"

@implementation YouTubeSearchBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setShowsCancelButton:NO animated:NO];
    
    // hide gray border
    self.backgroundImage = [[UIImage alloc] init];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
