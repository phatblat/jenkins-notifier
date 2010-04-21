//
//  CPingTool.h
//  PingTest
//
//  Created by Jonathan Wight on Mon Oct 13 2003.
//  Copyright (c) 2003 Toxic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <netinet/in.h>

/*! Name of notification sent when the PingTool starts pinging. */
extern NSString *TXPingToolDidStartNotification /* = @"TXPingToolDidStartNotification" */;
/*! Name of notification sent when the PingTool sends a packet. */
extern NSString *TXPingToolDidSendPacketNotification /* = @"TXPingToolDidSendPacketNotification" */;
/*! Name of notification sent when the PingTool receives a ping response. */
extern NSString *TXPingToolDidReceivePacketNotification /* = @"TXPingToolDidReceivePacketNotification" */;
/*! Name of notification sent when the PingTool times-out waiting for a ping response. */
extern NSString *TXPingToolDidLosePacketNotification /* = @"TXPingToolDidLosePacketNotification" */;
/*! Name of notification sent when the PingTool finishs pinging. */
extern NSString *TXPingToolDidFinishNotification /* = @"TXPingToolDidFinishNotification" */;
/*! Name of notification sent when the PingTool throws an exception. */
extern NSString *TXPingToolDidFailNotification;

/*!
 * @class CPingTool
 * @discussion A tool object for pinging a remote host one or more times and returning statistics on the quality of the ping. The object will communicate status of the pings by posting notifications.
 */
@interface CPingTool : NSObject {
	NSHost *host;
	NSTimeInterval timeout; 
	BOOL alwaysWaitFullTimeout;
	
	NSLock *lock;
	BOOL pingingFlag;
	int pingCount;
	struct sockaddr_in hostAddress;
	int socketHandle;
	
	NSMutableArray *statisticsHistory;
	int packetSequenceNumber;
	int packetsSent;
	int packetsReceived;
	NSTimeInterval averageResponse;
	BOOL pingFailed;
}

+ (id)pingToolWithHost:(NSHost *)inHost timeout:(NSTimeInterval)inTimeout;

- (id)init;

- (void)setHost:(NSHost *)inHost;
- (NSHost *)host;

/*!
 * @method setTimeout:
 * @discussion Set the ping timeout. Default is 1.0 seconds.
 */
- (void)setTimeout:(NSTimeInterval)inTimeout;
- (NSTimeInterval)timeout;

/*!
 * @method setAlwaysWaitFullTimeout:
 * @discussion Set to true (default) if you want the object to wait for the full timeout even if a response has already been received.
 */
- (void)setAlwaysWaitFullTimeout:(BOOL)inAlwaysWaitFullTimeout;
- (BOOL)alwaysWaitFullTimeout;

- (void)setPingCount:(int)inPingCount;
- (int)pingCount;

/**
 * @method inProgress
 * @discussion Returns true if pinging is in progress.
 */
- (BOOL)inProgress;

- (NSArray *)statisticsHistory;

/**
 * @method statistics
 * @discussion Returns a dictionary containing various statistics on the ping so far.
 */
- (NSDictionary *)statistics;

/*!
 * @method ping:
 * @abstract Start pinging. (Nonblocking)
 */
- (void)ping;

@end
