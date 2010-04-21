//
//  CPingTool.m
//  PingTest
//
//  Created by Jonathan Wight on Mon Oct 13 2003.
//  Copyright (c) 2003 Toxic Software. All rights reserved.
//

#import "CPingTool.h"

#import "CPingTool_Private.h"

#include <unistd.h>

NSString *TXPingToolDidStartNotification = @"TXPingToolDidStartNotification";
NSString *TXPingToolDidSendPacketNotification = @"TXPingToolDidSendPacketNotification";
NSString *TXPingToolDidReceivePacketNotification = @"TXPingToolDidReceivePacketNotification";
NSString *TXPingToolDidLosePacketNotification = @"TXPingToolDidLosePacketNotification";
NSString *TXPingToolDidFinishNotification = @"TXPingToolDidFinishNotification";
NSString *TXPingToolDidFailNotification = @"TXPingToolDidFailNotification";

#pragma mark -

@implementation CPingTool

+ (id)pingToolWithHost:(NSHost *)inHost timeout:(NSTimeInterval)inTimeout
{
CPingTool *thePingTool = [[[self alloc] init] autorelease];
[thePingTool setHost:inHost];
[thePingTool setTimeout:inTimeout];
return(thePingTool);
}

- (id)init
{
if ((self = [super init]) != NULL)
	{
	host = NULL;
	timeout = 1.0f;
	alwaysWaitFullTimeout = YES;
	
	lock = [[NSRecursiveLock alloc] init];
	[self setInProgress:NO];
	pingCount = 1;
//	hostAddress;
	socketHandle = -1;
	pingFailed = NO;
	}
return(self);
}

- (void)dealloc
{
	[host release]; host = NULL;
	[statisticsHistory release]; statisticsHistory = nil;
	[lock release]; lock = nil;
	
if (socketHandle != -1)
	{
	close(socketHandle);
	socketHandle = -1;
	}
//
[super dealloc];
}

#pragma mark -

- (void)setHost:(NSHost *)inHost
{
if ([self inProgress] == YES)
	[NSException raise:NSGenericException format:@"Cannot change attributes while ping in progress."];
if (host != inHost)
	{
	[host autorelease];
	host = [inHost retain];
	}
}

- (NSHost *)host
{
return(host);
}

- (void)setTimeout:(NSTimeInterval)inTimeout
{
if ([self inProgress] == YES)
	[NSException raise:NSGenericException format:@"Cannot change attributes while ping in progress."];
timeout = inTimeout;
}

- (NSTimeInterval)timeout
{
return(timeout);
}

- (void)setAlwaysWaitFullTimeout:(BOOL)inAlwaysWaitFullTimeout
{
if ([self inProgress] == YES)
	[NSException raise:NSGenericException format:@"Cannot change attributes while ping in progress."];
alwaysWaitFullTimeout = inAlwaysWaitFullTimeout;
}

- (BOOL)alwaysWaitFullTimeout
{
return(alwaysWaitFullTimeout);
}

- (void)setPingCount:(int)inPingCount
{
if ([self inProgress] == YES)
	[NSException raise:NSGenericException format:@"Cannot change attributes while ping in progress."];
pingCount = inPingCount;
}

- (int)pingCount
{
return(pingCount);
}

#pragma mark -

- (BOOL)inProgress
{
[lock lock];
const BOOL thePingingFlag = pingingFlag;
[lock unlock];
return(thePingingFlag);
}

- (NSArray *)statisticsHistory
{
// Make a copy of the array so that the receiver doesn't have to worry about threading...
[lock lock];
NSArray *theStatisticsHistory = [[statisticsHistory copy] autorelease];
[lock unlock];
return(theStatisticsHistory);
}

- (NSDictionary *)statistics
{
[lock lock];
NSDictionary *theStatistics = [NSDictionary dictionaryWithObjectsAndKeys:
	[NSNumber numberWithInt:packetsSent], @"packetsSent",
	[NSNumber numberWithInt:packetsReceived], @"packetsReceived",
	[NSNumber numberWithDouble:averageResponse], @"averageResponse",
	NULL];
[lock unlock];
return(theStatistics);
}

#pragma mark -

- (void)ping
{
	// ### Check parameters and attributes
	if (host == NULL || timeout < 0.0 || pingCount < 1)
		[NSException raise:NSGenericException format:@"Invalid parameters."];
		
	pingFailed = NO;
	//
	[NSThread detachNewThreadSelector:@selector(threadHandler:) toTarget:self withObject:NULL];
}

@end
