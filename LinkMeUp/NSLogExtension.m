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

void ExtendNSLog(const char *time, const char *file, int lineNumber, const char *functionName, NSString *format, ...)
{
    // Type to hold information about variable arguments.
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    // NSLog only adds a newline to the end of the NSLog format if one is not already there.
    // Here we are utilizing this feature of NSLog()
    if (![format hasSuffix: @"\n"])
    {
        format = [format stringByAppendingString: @"\n"];
    }
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    // End using variable argument list.
    va_end (ap);
    
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    
    // Log message
    NSString *logMessage = [NSString stringWithFormat:@"%s (%s:%d) %s", time, [fileName UTF8String], lineNumber, [body UTF8String]];
    // NSString *logMessage = [NSString stringWithFormat:@"(%s) (%s:%d) %s", functionName, [fileName UTF8String], lineNumber, [body UTF8String]];
    
    // Append to sessionLogs object
    LinkMeUpAppDelegate *appDelegate = (LinkMeUpAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.sessionLogs.messages addObject: logMessage];
    
    fprintf(stderr, [logMessage UTF8String]);
}

@end
