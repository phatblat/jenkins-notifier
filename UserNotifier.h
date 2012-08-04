//
//  UserNotifier.h
//  JenkinsNotifier
//
//  Created on 7/29/12.
//
//

#import <Foundation/Foundation.h>

@interface UserNotifier : NSObject

+ (BOOL)isAvailable;

+ (UserNotifier*)instance;

- (void)postNotificationWithName:(NSString*)notify
                             job:(NSString*)job
                           title:(NSString*)title
                     description:(NSString*)desc
                           image:(NSImage*)img
                        isSticky:(BOOL)isSticky;
@end
