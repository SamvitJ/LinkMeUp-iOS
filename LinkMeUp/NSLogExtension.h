//
//  NSLogExtension.h
//  LinkMeUp
//
//  Created by Samvit Jain on 7/26/15.
//
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
    #define NSLog(args...) ExtendNSLog(__TIME__,__FILE__,__LINE__,__PRETTY_FUNCTION__,args);
#else
    #define NSLog(...);
#endif

@interface NSLogExtension : NSObject

void ExtendNSLog(const char *time, const char *file, int lineNumber, const char *functionName, NSString *format, ...);

@end
