//
//  CPingTool_Private.h
//  PingToolTest
//
//  Created by Jonathan Wight on 10/01/2004.
//  Copyright 2004 Toxic Software. All rights reserved.
//

#import "CPingTool.h"

#import <Cocoa/Cocoa.h>

@interface CPingTool (CPingTool_Private)

- (void)start;
- (void)finish;
- (void)pingOnce;

- (struct PingICMPPacket)createPacket:(NSDate *)inTimestamp;
- (void)sendPacket:(struct PingICMPPacket)inPacket;
- (BOOL)receivePacket:(struct PingICMPPacket *)outPacket dateReceived:(NSDate **)outDate;

- (void)setInProgress:(BOOL)inPinging;
- (void)setStatisticsHistory:(NSArray *)inArray;
- (void)insertObject:(id)inObject inStatisticsHistoryAtIndex:(unsigned int)inIndex;
- (void)removeObjectFromStatisticsHistoryAtIndex:(unsigned int)inIndex;

- (IBAction)actionPing:(id)inSender;

@end
