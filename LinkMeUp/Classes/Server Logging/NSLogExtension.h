//
//  NSLogExtension.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/26/15.
//
//

#import <Foundation/Foundation.h>

#ifndef DEBUG
    #define NSLog(args...) ExtendNSLog(__FILE__,__LINE__,args);
#endif

@interface NSLogExtension : NSObject

void ExtendNSLog(const char *file, int lineNumber, NSString *format, ...);

@end
