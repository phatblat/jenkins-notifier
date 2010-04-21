//
//  CPingTool_Private.m
//  PingToolTest
//
//  Created by Jonathan Wight on 10/01/2004.
//  Copyright 2004 Toxic Software. All rights reserved.
//

#import "CPingTool_Private.h"

#import "NSDate_SysTimeExtensions.h"
#import "NSHost_PingToolExtensions.h"

#include <arpa/inet.h>
#include <errno.h>
#include <netdb.h>
#include <netinet/in_systm.h>
#include <netinet/in.h>
#include <netinet/ip_var.h>
#include <netinet/ip.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <netinet/ip_icmp.h>

struct PingICMPPacket 
{
    struct icmp 	icmpHeader; // required icmp header
    struct timeval 	packetTimeStamp; // our optional data will be the packet send time.
};

static int in_cksum(u_short *addr, int len);

@implementation CPingTool (CPingTool_Private)

- (void)threadHandler:(id)inObject
{
	NSAutoreleasePool *theAutoreleasePool = [[NSAutoreleasePool alloc] init];
	//
	[self setInProgress:YES];

	[self start];
	while (packetSequenceNumber < pingCount) 
		{
		[self pingOnce];
		[lock lock];
		++packetSequenceNumber;
		[lock unlock];
		}
	[self finish];

	[self setInProgress:NO];

	//
	[theAutoreleasePool drain];
}

- (void)start
{
	@try {
		if (!pingFailed)
		{
			// ### Store the host address.
			struct sockaddr_in theHostAddress = [host asSockAddr];
			// ### Getting the protocol information we need to create the socket.
			struct protoent *theProtocolInformation = getprotobyname("icmp");
			if (theProtocolInformation == NULL)
				[NSException raise:NSGenericException format:@"Could not get an 'icmp' protocol."];
			// ### Create the socket. Now creating the socket which will be used for pinging the remote host. Note previous to MacOSX 10.2 this required a raw socket which required root permissions.  However, now in 10.2.x you can simply create a datagram socket and can use that to ping remote hosts.
			int theSocketHandle = socket(AF_INET, SOCK_DGRAM, theProtocolInformation->p_proto);
			if (theSocketHandle < 0)
				[NSException raise:NSGenericException format:@"Could not create socket"];
			// ### Increase the socket buffer size (to 64KB)
			const int kReceiveSocketBufferSize = 64 * 1024;
			(void)setsockopt(theSocketHandle, SOL_SOCKET, SO_RCVBUF, &kReceiveSocketBufferSize, sizeof(kReceiveSocketBufferSize));
			// ### Setting the ping timeout to one second. This way a recieve call will timeout after 1 second later on.  This saves us from having to use UNIX signal alarms for timeouts
			struct timeval thePingTimeout = { .tv_sec = floor(timeout), .tv_usec = (timeout - floor(timeout)) * 1000000 };
			int theError = setsockopt(theSocketHandle, SOL_SOCKET, SO_RCVTIMEO, &thePingTimeout, sizeof(thePingTimeout));
			if (theError != 0)
			{
				close(theSocketHandle);
				[NSException raise:NSGenericException format:@"Could not set timeout"];
			}
			// ### Set the object attributes...
			[lock lock];
			hostAddress = theHostAddress;
			socketHandle = theSocketHandle;
			//
			NSArray *initialStatHistory = [[NSArray alloc] init];
			[self setStatisticsHistory:initialStatHistory];
			[initialStatHistory release];
			
			packetSequenceNumber = 0;
			packetsSent = 0;
			packetsReceived = 0;
			averageResponse = INFINITY;
			[lock unlock];
			
			// ### Notify the world
			[[NSNotificationCenter defaultCenter] postNotificationName:TXPingToolDidStartNotification object:self userInfo:NULL];		
		}
	}
	@catch (NSException * e) {
		NSLog(@"ERROR: %@", [e reason]);
		NSDictionary *theDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									   self.host, @"host",
									   NULL];
		
		pingFailed = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:TXPingToolDidFailNotification object:self userInfo:theDictionary];
		
	}
}

- (void)finish
{
[lock lock];
close(socketHandle);
socketHandle = -1;
[lock unlock];

[[NSNotificationCenter defaultCenter] postNotificationName:TXPingToolDidFinishNotification object:self userInfo:NULL];
}

- (void)pingOnce
{
	if (!pingFailed)
	{
		NSDictionary *theDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:packetSequenceNumber], @"packetSequenceNumber",
			self.host, @"host",
			NULL];
		[[NSNotificationCenter defaultCenter] postNotificationName:TXPingToolDidSendPacketNotification object:self userInfo:theDictionary];
		//
		NSDate *thePacketSentTime = [NSDate date];
		// ### Create a packet and send it.
		struct PingICMPPacket thePacket = [self createPacket:thePacketSentTime];
		[self sendPacket:thePacket];
		// ### Keep looping until we get a valid packet or the timeout triggers.
		NSDate *theReceivedTime = NULL;
		struct PingICMPPacket theReceivedPacket;
		BOOL theGotResponseFlag = NO;
		do
			{
			if ([self receivePacket:&theReceivedPacket dateReceived:&theReceivedTime] == YES)
				theGotResponseFlag = YES;
			}
		while ([[NSDate date] timeIntervalSinceDate:thePacketSentTime] < timeout && (alwaysWaitFullTimeout == YES || theGotResponseFlag == NO));
		NSMutableDictionary *theStatistics = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:theGotResponseFlag], @"received",
			[NSNumber numberWithInt:packetsSent], @"packetsSent",
			self.host, @"host",
			NULL];
		// ### We either got a response or we didn't.
		if (theGotResponseFlag == YES)
			{
			NSDate *thePacketTime = [NSDate dateWithTimeVal:theReceivedPacket.packetTimeStamp];
			const NSTimeInterval theRoundTripTime = [theReceivedTime timeIntervalSinceDate:thePacketTime];
			//
			[lock lock];
			// Compute the average response time (we can't do math with infinity so we set the initial response to 0).
			if (!isfinite(averageResponse)) averageResponse = 0.0;
			averageResponse = (averageResponse * (double)(packetsReceived - 1) + theRoundTripTime) / packetsReceived;
			[lock unlock];

			const int thePacketSequence = theReceivedPacket.icmpHeader.icmp_seq;

			[theStatistics setObject:[NSNumber numberWithDouble:averageResponse] forKey:@"averageResponse"];
			[theStatistics setObject:[NSNumber numberWithDouble:theRoundTripTime] forKey:@"roundTripTime"];
			[theStatistics setObject:[NSNumber numberWithInt:thePacketSequence] forKey:@"packetSequenceNumber"];
			}

		[lock lock];
		[self insertObject:theStatistics inStatisticsHistoryAtIndex:[statisticsHistory count]];
		[lock unlock];

		if (theGotResponseFlag == YES)
			{
			[[NSNotificationCenter defaultCenter] postNotificationName:TXPingToolDidReceivePacketNotification object:self userInfo:theStatistics];
			}
		else
			{
			[[NSNotificationCenter defaultCenter] postNotificationName:TXPingToolDidLosePacketNotification object:self userInfo:theStatistics];
			}
	}
}

- (struct PingICMPPacket)createPacket:(NSDate *)inTimestamp
{
struct PingICMPPacket thePacket;
// ICMP type is an echo packet which is the packet type for a ping.
thePacket.icmpHeader.icmp_type = ICMP_ECHO;
// Zero code for ping packet.
thePacket.icmpHeader.icmp_code = 0;
// Sequence number of the packet is whatever is passed to us
thePacket.icmpHeader.icmp_seq = packetSequenceNumber;
// Add our PID as the identifier so we know later the ping originated from us.
thePacket.icmpHeader.icmp_id = getpid(); 
// Now we will get time of day so we can add it to the "extra" data on the ICMP packet. The time of day will allow us to calculate the round trip time on the ping upon recieveing the echo packet
thePacket.packetTimeStamp = [inTimestamp asTimeval];
// Now that we have the filled out packet we will calculate the checksum for the packet. We actually will calculate checksum but only after we have everything filled out and set the checksum value to zero (for calculation).
thePacket.icmpHeader.icmp_cksum = 0;
// The in_cksum function will calculate the checksum for us given the packet and its length.
thePacket.icmpHeader.icmp_cksum = in_cksum((u_short *)&thePacket, sizeof(thePacket));
return(thePacket);
}

- (void)sendPacket:(struct PingICMPPacket)inPacket
{

	@try {
		if (!pingFailed)
		{
			ssize_t sizeOfDataSent = sendto(socketHandle, &inPacket, sizeof(inPacket), 0, (struct sockaddr*)&hostAddress, sizeof(hostAddress));
			
			// if size of data sent is -1 (indicating error) or not size we wanted then we have a problem
			if ((sizeOfDataSent < 0) || (sizeOfDataSent != sizeof(inPacket)))
			{
				[NSException raise:NSGenericException format:@"Could not send packet."];
			}

			[lock lock];
			++packetsSent;
			[lock unlock];
		}	
	}
	@catch (NSException * e) {
		NSLog(@"ERROR: %@", [e reason]);
		NSDictionary *theDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									   self.host, @"host",
									   NULL];
		
		pingFailed = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:TXPingToolDidFailNotification object:self userInfo:theDictionary];
		
	}	
}

- (BOOL)receivePacket:(struct PingICMPPacket *)outPacket dateReceived:(NSDate **)outDate
{
	@try {
		if (!pingFailed)
		{
			const int kBufferSize = 2 * 1024;
			char thePingReplyBuffer[kBufferSize];
			memset(thePingReplyBuffer, 0, kBufferSize);
			// ###
			struct sockaddr_in theRemoteHost;
			socklen_t theSizeOfRemoteHost = sizeof(theRemoteHost);
			ssize_t theNumberOfBytesReceived = recvfrom(socketHandle, thePingReplyBuffer, sizeof(thePingReplyBuffer), 0, (struct sockaddr *)&theRemoteHost, &theSizeOfRemoteHost);
			// Get the current time for determining round trip time (we do this now to make the time calculation more accurate).
			NSDate *theReceivedTime = [NSDate date];
			// Error receiving data, return error. return the UNIX errno variable which would be set by recvfrom.
			if (theNumberOfBytesReceived < 0)
				{
				if (errno == EAGAIN) 
					return(NO);
				else
					[NSException raise:NSGenericException format:@"Error"];
				}
			// Interpret packet as IP packet to remove header
			struct ip *thePacketInterpetedAsIPPacket = (struct ip*)thePingReplyBuffer;
			// The ip_hl item within the IP packet has the length of the IP header expressed as bytes (shifted right twice, thus need to shift left to compensate.
			const int theIPHeaderLength = thePacketInterpetedAsIPPacket->ip_hl << 2;
			// Now we know the IP header length we can get a pointer to the ICMP section of the packet
			struct PingICMPPacket *theICMPPacket = (struct PingICMPPacket*)(thePingReplyBuffer + theIPHeaderLength);
			const int theICMPPacketSize = theNumberOfBytesReceived - theIPHeaderLength;
			if (theICMPPacketSize >= sizeof(struct PingICMPPacket))
			{
			// This packet also has to be an ICMP echo reply packet to the one.
			if (theICMPPacket->icmpHeader.icmp_type == ICMP_ECHOREPLY)
			{
				// To be our packet the id on the packet has to match our PID. This is because in the echo the id wouldn't change and we sent pid as the id.
				if (theICMPPacket->icmpHeader.icmp_id == getpid())
					{
					[lock lock];
					++packetsReceived;			
					*outPacket = *theICMPPacket;
					*outDate = theReceivedTime;
					[lock unlock];
					return(YES);
					}
				}
			}
		}
	}
	@catch (NSException * e) {
		NSLog(@"ERROR: %@", [e reason]);
		NSDictionary *theDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									   self.host, @"host",
									   NULL];
		pingFailed = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:TXPingToolDidFailNotification object:self userInfo:theDictionary];
	}
	
	return(NO);
}

#pragma mark -

- (void)setInProgress:(BOOL)inPinging
{
	if (!pingFailed)
	{
		[lock lock];
		pingingFlag = inPinging;
		[lock unlock];
	}
}

- (void)setStatisticsHistory:(NSArray *)inArray
{
	[lock lock];
	
	[inArray retain];
	[statisticsHistory release];
	statisticsHistory = [inArray mutableCopy];
	[inArray release];
	
	[lock unlock];
}

- (void)insertObject:(id)inObject inStatisticsHistoryAtIndex:(unsigned int)inIndex
{
[lock lock];
[statisticsHistory insertObject:inObject atIndex:inIndex];
[lock unlock];
}

- (void)removeObjectFromStatisticsHistoryAtIndex:(unsigned int)inIndex;
{
[lock lock];
[statisticsHistory removeObjectAtIndex:inIndex];
[lock unlock];
}

- (IBAction)actionPing:(id)inSender
{
[self ping];
}

@end

// Here stealing the in_cksum function which computes checksum for our packets from original ping.
static int in_cksum(u_short *addr, int len)
{
register int nleft = len;
register u_short *w = addr;
register int sum = 0;
u_short answer = 0;

// Our algorithm is simple, using a 32 bit accumulator (sum), we add sequential 16 bit words to it, and at the end, fold back all the carry bits from the top 16 bits into the lower 16 bits...
while (nleft > 1) 
	{
	sum += *w++;
	nleft -= 2;
	}

// Mop up an odd byte, if necessary...
if (nleft == 1)
	{
	*(u_char *)(&answer) = *(u_char *)w ;
	sum += answer;
	}

// Add back carry outs from top 16 bits to low 16 bits...
sum = (sum >> 16) + (sum & 0xffff);	/* add hi 16 to low 16 */
sum += (sum >> 16);			/* add carry */
answer = ~sum;				/* truncate to 16 bits */
return(answer);
}
