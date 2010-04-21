//
//  NSDate_SysTimeExtensions.m
//  PingTest
//
//  Created by Jonathan Wight on Mon Oct 13 2003.
//  Copyright (c) 2003 Toxic Software. All rights reserved.
//

#import "NSDate_SysTimeExtensions.h"

@implementation NSDate (NSDate_SysTimeExtensions)

+ (NSDate *)dateWithTimeVal:(struct timeval)inTime
{
const NSTimeInterval theTimeIntervalSince1970 = (double)inTime.tv_sec + (double)inTime.tv_usec / 1000000.0; 
return([self dateWithTimeIntervalSince1970:theTimeIntervalSince1970]);
}

- (struct timeval)asTimeval
{
const NSTimeInterval theTimeIntervalSince1970 = [self timeIntervalSince1970];
struct timeval theTimeVal;
theTimeVal.tv_sec = (int32_t)theTimeIntervalSince1970;
theTimeVal.tv_usec = (int32_t)((theTimeIntervalSince1970 - floor(theTimeIntervalSince1970)) * 1000000.0);
return(theTimeVal);
}

@end
