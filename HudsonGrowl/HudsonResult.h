//
//  HudsonResult.h
//  HudsonGrowl
//
//  Created by Benjamin Broll on 19.10.09.
//  Copyright 2009 BBG Entertainment GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HudsonResult : NSObject {
	NSString* job;
	int buildNr;
	BOOL success;
	
	NSString* link;
}

@property (readonly) NSString* job;
@property (readonly) int buildNr;
@property (readonly) BOOL success;
@property (readonly) NSString* link;

+(HudsonResult*)resultWithJob:(NSString*)job buildNr:(int)nr success:(BOOL)success link:(NSString*)link;
-(id)initWithJob:(NSString*)job buildNr:(int)nr success:(BOOL)success link:(NSString*)link;

@end
