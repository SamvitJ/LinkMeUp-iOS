//
//  YouTubeSearchBar.m
//  LinkMeUp
//
//  Created by Samvit Jain on 8/6/14.
//
//

#import "YouTubeSearchBar.h"

#import "Constants.h"

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
    
    //CGFloat frameExpansion = 15.0;
    //self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height + frameExpansion);
    
    for (UIView *view in self.subviews)
    {
        for (UIView *subview in view.subviews)
        {
            if ([subview isKindOfClass: [UITextField class]])
            {
                UITextField *textField = (UITextField *)subview;
                
                CGFloat horizontExpansion = 3.0;
                CGFloat verticalExpansion = 3.0;
                
                textField.frame = CGRectMake(textField.frame.origin.x - horizontExpansion, textField.frame.origin.y - verticalExpansion, textField.frame.size.width + (2 * horizontExpansion), textField.frame.size.height + verticalExpansion /*+ frameExpansion*/);
                
                textField.borderStyle = UITextBorderStyleRoundedRect;
                textField.layer.cornerRadius = 5.0;
                
                //textField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
                //textField.layer.borderWidth = 1.0;
                
                textField.font = HELV_15;
                
                //NSLog(@"%@", textField.font);
            }
        }
    }
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
