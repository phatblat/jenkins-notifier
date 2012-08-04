//
//  UserNotifier.m
//  JenkinsNotifier
//
//  Created on 7/29/12.
//
//

#import "UserNotifier.h"

@implementation UserNotifier

+ (BOOL)isAvailable
{
  return NSClassFromString(@"NSUserNotificationCenter") != NULL;
}

+ (UserNotifier*)instance
{
  UserNotifier* instance = [[[UserNotifier alloc] init] autorelease];
  
  return instance;
}

- (void)postNotificationWithName:(NSString*)notify
                             job:(NSString*)job
                           title:(NSString*)title
                     description:(NSString*)desc
                           image:(NSImage*)img
                        isSticky:(BOOL)isSticky
{
  NSUserNotification *notification = [[[NSUserNotification alloc] init] autorelease];
  
  notification.title = title;
  notification.subtitle = desc;
  notification.userInfo = [NSDictionary dictionaryWithObject:job forKey:@"job"];
  
  [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification: notification];
}

@end
