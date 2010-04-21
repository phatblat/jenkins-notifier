//
//  NSHost_PingToolExtensions.m
//  PingTest
//
//  Created by Jonathan Wight on Mon Oct 13 2003.
//  Copyright (c) 2003 Toxic Software. All rights reserved.
//

#import "NSHost_PingToolExtensions.h"

#include <arpa/inet.h>
#include <netdb.h>

static int LookupoutHostAddress(const char* inHost, struct sockaddr_in* outHostAddress);

@implementation NSHost (NSHost_PingToolExtensions)

- (struct sockaddr_in)asSockAddr
{
struct sockaddr_in theSockAddr;
int theResult = LookupoutHostAddress([[self name] UTF8String], &theSockAddr); // NOTE: changed deprecated cString to UTF8String.  is this the right thing to do?
if (theResult != 0)
	[NSException raise:NSGenericException format:@"Could not lookup address"];
return(theSockAddr);
}

@end

int LookupoutHostAddress(const char *inHost, struct sockaddr_in *outHostAddress)
{
// Checking input argument for validity
if (inHost == NULL || outHostAddress == NULL)
	return(EINVAL);
// Initalizing host address
struct hostent *theHostInformation;
memset(outHostAddress, 0, sizeof(struct sockaddr_in));
// Calling inet_addr to try to interpret the input address as a IP string "xx.xx.xx.xx.xx.
outHostAddress->sin_addr.s_addr = inet_addr(inHost);
// Checking to see if IP address was got correctly from character string.
if (outHostAddress->sin_addr.s_addr != INADDR_NONE) //Success no error returned!
	{	
	// Setting socket family to internet (TCP/IP) since know it was IP address interpreted
	outHostAddress->sin_family = AF_INET;
	}
else
	{
 	// The inet_addr call failed because the string isn't an IP address. Instead we will try to interpret it as a host name (e.g. www.google.com). Now try with gethostbyname...
	theHostInformation = gethostbyname(inHost);
	if (theHostInformation == NULL)
		{
		// Failure unable to interpret character string as host name. We give up here by returning can't find host (unreachable host).
		return(EHOSTUNREACH);
		}
	// Setting the socket family for connecting to the host.  We get this information from the theHostInformation structure directly
	outHostAddress->sin_family = theHostInformation->h_addrtype;
	// Now getting the internet address structure from our host information structure. We copy the structure into ours using a memmove 
	memmove(&outHostAddress->sin_addr, theHostInformation->h_addr, theHostInformation->h_length);
	}
// Now for the host we have the address and connection family for the host we can return this information
return(0);
}
