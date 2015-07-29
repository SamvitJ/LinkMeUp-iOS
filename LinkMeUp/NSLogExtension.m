//
//  NSLogExtension.m
//  LinkMeUp
//
//  Created by Samvit Jain on 7/26/15.
//
//

#import "NSLogExtension.h"

#import "LinkMeUpAppDelegate.h"

@implementation NSLogExtension

void ExtendNSLog(const char *file, int lineNumber, NSString *format, ...)
{
    // Type to hold information about variable arguments.
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    // NSLog only adds a newline to the end of the NSLog format if one is not already there.
    // Here we are utilizing this feature of NSLog()
    if (![format hasSuffix: @"\n"])
        format = [format stringByAppendingString: @"\n"];
    
    /* NSRange rangeError = [format rangeOfString: @"Error"];
    if (rangeError.location != NSNotFound)
    {
    
    } */
    
    // Log message body
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    // End using variable argument list.
    va_end (ap);
    
    // File name containing log message
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    
    // Create log message
    int fileMaxLength = 32;
    NSString *shortFileName = ([fileName length] > fileMaxLength ? [fileName substringToIndex: fileMaxLength] : fileName);
    
    const char *fileAndLine = [[NSString stringWithFormat:@"%@:%d", shortFileName, lineNumber] UTF8String];
    NSString *logMessage = [NSString stringWithFormat:@"%-37s %s", fileAndLine, [body UTF8String]];
    
    // Append to sessionLogs object
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.sessionLogs.messages addObject: logMessage];
    
    // Print to console
    // fprintf(stderr, [logMessage UTF8String]);
    // NSLogv(logMessage, ap);
}

@end
