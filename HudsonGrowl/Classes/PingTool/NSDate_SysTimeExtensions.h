//
//  NSDate_SysTimeExtensions.h
//  PingTest
//
//  Created by Jonathan Wight on Mon Oct 13 2003.
//  Copyright (c) 2003 Toxic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <sys/time.h>

/**
 * @category NSDate (NSDate_SysTimeExtensions)
 * @discussion Category providing convenience methods for dealing with sys/time.h datatypes.
 */
@interface NSDate (NSDate_SysTimeExtensions)

+ (NSDate *)dateWithTimeVal:(struct timeval)inTime;

- (struct timeval)asTimeval;

@end
