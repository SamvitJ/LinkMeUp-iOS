//
//  mySearchBar.m
//  LinkMeUp
//
//  Created by Samvit Jain on 8/3/14.
//
//

#import "SearchBarNoCancel.h"

@implementation SearchBarNoCancel

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
