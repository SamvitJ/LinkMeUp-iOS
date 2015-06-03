//
//  Constants.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/2/14.
//
//

#import "Constants.h"

@implementation Constants


#pragma mark - String methods

// converts NSString to URL encoded NSString
+ (NSString *)urlEncodeString:(NSString *)string
{
    return (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
}

// converts an NSDate to an NSString
+ (NSString *)dateToString:(NSDate *)date
{
    // date label
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale: [NSLocale autoupdatingCurrentLocale]];
    [formatter setDateStyle: NSDateFormatterMediumStyle];
    [formatter setDoesRelativeDateFormatting: YES];
    
    // if recent, include time
    BOOL isRecent = !(([[formatter stringFromDate:date] rangeOfString:@"Today" options:NSCaseInsensitiveSearch].location == NSNotFound) &&
                      ([[formatter stringFromDate:date] rangeOfString:@"Yesterday" options:NSCaseInsensitiveSearch].location == NSNotFound));
    [formatter setTimeStyle: (isRecent) ? NSDateFormatterShortStyle : NSDateFormatterNoStyle];
    
    return [formatter stringFromDate:date];
}

// convert ISO8601 format date/time string to float seconds
+ (NSNumber *)ISO8601FormatToFloatSeconds:(NSString *)duration
{
    NSString *formatString = [duration copy];
    
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    
    formatString = [formatString substringFromIndex:[formatString rangeOfString:@"T"].location];
    
    // only one letter remains after parsing
    while ([formatString length] > 1)
    {
        // remove first char (T, H, M, or S)
        formatString = [formatString substringFromIndex:1];
        
        NSScanner *scanner = [[NSScanner alloc] initWithString:formatString];
        
        // extract next integer in format string
        NSString *nextInteger = [[NSString alloc] init];
        [scanner scanCharactersFromSet:DIGITS_SET intoString:&nextInteger];
        
        // determine range of next integer
        NSRange rangeOfNextInteger = [formatString rangeOfString:nextInteger];
        
        // delete parsed integer from format string
        formatString = [formatString substringFromIndex:rangeOfNextInteger.location + rangeOfNextInteger.length];
        
        if ([[formatString substringToIndex:1] isEqualToString:@"H"])
            hours = [nextInteger intValue];
        
        else if ([[formatString substringToIndex:1] isEqualToString:@"M"])
            minutes = [nextInteger intValue];
        
        else if ([[formatString substringToIndex:1] isEqualToString:@"S"])
            seconds = [nextInteger intValue];
    }
    
    //NSLog(@"Video length (seconds): %f", (hours * 3600.0) + (minutes * 60.0) + (seconds * 1.0));
    return [NSNumber numberWithFloat:((hours * 3600.0) + (minutes * 60.0) + (seconds * 1.0))];
}

// returns comma-separated string representation of array objects
+ (NSString *)stringForArray:(NSArray *)array withKey:(NSString *)key
{
    NSMutableString *stringRepresentation = [NSMutableString stringWithFormat:@""];
    
    for (int i = 0; i < [array count]; i++)
    {
        if (key) // array of dictionaries
        {
            NSDictionary *current = [array objectAtIndex:i];
            [stringRepresentation appendString: [current objectForKey:key]];
        }
        
        else // array of strings
        {
            [stringRepresentation appendString: [array objectAtIndex:i]];
        }
        
        // last object
        if (i == [array count] - 1)
        {
            continue;
        }
        
        // second to last object
        else if (i == [array count] - 2)
        {
            if ([array count] == 2)
                [stringRepresentation appendString:@" and "];
            
            else // oxford comma
                [stringRepresentation appendString:@", and "];
        }
        
        else // all other objects
        {
            [stringRepresentation appendString:@", "];
        }
    }
    
    return stringRepresentation;
}



#pragma mark - PFUser name

// returns name of user if not null; else returns username
+ (NSString *)nameElseUsername:(PFUser *)user
{
    return ([user objectForKey:@"name"] ? [user objectForKey:@"name"] : user.username);
}



#pragma mark - Phone numbers

// remove all non-numeric characters (i.e. (, ), -) from phone number
+ (NSString *)removeNonNumericFromPhoneNumber:(NSString *)phone
{
    NSCharacterSet *excludedChars = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [[phone componentsSeparatedByCharactersInSet: excludedChars] componentsJoinedByString:@""];
}

// return array containing both variants of phone number (w/ and w/o country code), if applicable
+ (NSArray *)allVariantsOfPhoneNumber:(NSString *)phone
{
    NSMutableArray *allPhoneNumbers = [[NSMutableArray alloc] init];
    
    // add original
    [allPhoneNumbers addObject:phone];
    
    // add other variant if applicable
    if ([phone length] > phoneLengthSansUSCC)
    {
        NSString *phoneSansCC = [phone substringFromIndex:[phone length] - phoneLengthSansUSCC];
        [allPhoneNumbers addObject:phoneSansCC];
    }
    else if ([phone length] == phoneLengthSansUSCC)
    {
        NSString *phoneWithCC = [@"1" stringByAppendingString:phone];
        [allPhoneNumbers addObject:phoneWithCC];
    }
    else // non standard (i.e. international)
    {
        // do nothing
    }

    return [allPhoneNumbers copy];
}

// returns true if phone numbers are equal, else return false
+ (BOOL)comparePhone1:(NSString *)phone1 withPhone2:(NSString *)phone2
{
    NSArray *allVariantsPhone1 = [Constants allVariantsOfPhoneNumber:phone1];
    NSArray *allVariantsPhone2 = [Constants allVariantsOfPhoneNumber:phone2];
    
    for (NSString *phone1Variant in allVariantsPhone1)
    {
        for (NSString *phone2Variant in allVariantsPhone2)
        {
            if ([phone1Variant isEqualToString:phone2Variant])
            {
                return true;
            }
        }
    }
    
    return false;
}



#pragma mark - LinkMeUp logo label

+ (UILabel *)createLogoLabel
{
    UILabel *logo = [[UILabel alloc] init];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSMutableAttributedString *logoText = [[NSMutableAttributedString alloc] initWithString: @"LinkMeUp"
                                                                                 attributes: @{NSParagraphStyleAttributeName: paragraphStyle,
                                                                                               NSFontAttributeName: HELV_32,
                                                                                               NSForegroundColorAttributeName: LIGHT_TURQ}];
    [logoText addAttribute:NSFontAttributeName
                     value:HELV_THIN_ITAL_32
                     range:NSMakeRange(@"Link".length, @"Me".length)];
    
    [logo setAttributedText:logoText];
    
    return logo;
}



#pragma mark - Back button

// create back button with default text "Back"
+ (UIButton *)createBackButton
{
    return [Constants createBackButtonWithText:@"Back"];
}

// create back button with custom text
+ (UIButton *)createBackButtonWithText:(NSString *)text
{
    UIButton *backButton = [[UIButton alloc] initWithFrame: CGRectMake(5.0f, 36.0f, 36.0f + (9.0f * text.length), 30.0f)];
    
    UIImage *backIcon = [UIImage imageNamed:@"Back"/*@"glyphicons_224_chevron-left"*/];
    backIcon = [UIImage imageWithCGImage:[backIcon CGImage]
                                   scale:(backIcon.scale * 13.0)
                             orientation:UIImageOrientationUp];
    backIcon = [Constants renderImage:backIcon inColor:LIGHT_TURQ];
    
    [backButton setImage:backIcon forState:UIControlStateNormal];
    [backButton setTitle:[NSString stringWithFormat:@"  %@", text] forState:UIControlStateNormal];
    [backButton setTitleColor:LIGHT_TURQ forState:UIControlStateNormal];
    backButton.titleLabel.font = GILL_20;
    
    return backButton;
}


#pragma mark - UIButton state methods

+ (void)enableButton:(UIButton *)button
{
    button.titleLabel.font = CHALK_19;
    button.alpha = 1.0;
    button.enabled = YES;
    
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    button.layer.borderWidth = 1.0f;
}

+ (void)disableButton:(UIButton *)button
{
    button.titleLabel.font = CHALK_LIGHT_19;
    button.alpha = ALPHA_DISABLED;
    button.enabled = NO;
    
    button.layer.borderColor = [UIColor clearColor].CGColor;
}

+ (void)highlightButton:(UIButton *)button
{
    button.titleLabel.font = CHALK_19;
    button.alpha = 1.0;
    
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    button.layer.borderWidth = 1.0f;
}

+ (void)fadeButton:(UIButton *)button
{
    button.titleLabel.font = CHALK_LIGHT_19;
    button.alpha = ALPHA_DISABLED;
    
    button.layer.borderColor = [UIColor clearColor].CGColor;
}



#pragma mark - UIGraphics methods

// recolor icon image
+ (UIImage *)renderImage:(UIImage *)image inColor:(UIColor *)color
{
    UIImage *original = image;
    
    CGRect rect = CGRectMake(0.0f, 0.0f, original.size.width, original.size.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, original.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    [original drawInRect:rect];
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    
    UIImage *final = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return final;
}

// add a foreground image to background image
+ (UIImage *)drawImage:(UIImage*)fgImage inImage:(UIImage*)bgImage atPoint:(CGPoint) point
{
    UIGraphicsBeginImageContextWithOptions(bgImage.size, FALSE, 0.0);
    [bgImage drawInRect:CGRectMake(0.0f, 0.0f, bgImage.size.width, bgImage.size.height)];
    [fgImage drawInRect:CGRectMake(point.x, point.y, fgImage.size.width, fgImage.size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
