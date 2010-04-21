//
//  NSHost_PingToolExtensions.h
//  PingTest
//
//  Created by Jonathan Wight on Mon Oct 13 2003.
//  Copyright (c) 2003 Toxic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <netinet/in.h>

@interface NSHost (NSHost_PingToolExtensions)

- (struct sockaddr_in)asSockAddr;

@end
