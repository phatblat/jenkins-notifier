//
//  HudsonResult.m
//  HudsonGrowl
//
//  Created by Benjamin Broll on 19.10.09.
//  Copyright 2009 BBG Entertainment GmbH. All rights reserved.
//

#import "HudsonResult.h"


@implementation HudsonResult

@synthesize job, buildNr, success, link;


+(HudsonResult*)resultWithJob:(NSString*)job buildNr:(int)nr success:(BOOL)success link:(NSString*)link {
	return [[[self alloc] initWithJob:job buildNr:nr success:success link:link] autorelease];
}

-(id)initWithJob:(NSString*)j buildNr:(int)nr success:(BOOL)s link:(NSString*)l {
	if ((self = [super init])) {
		job = [j retain];
		buildNr = nr;
		success = s;
		link = [l retain];
	}
	
	return self;
}


- (NSString*) description {
	return [NSString stringWithFormat:@"job: %@, buildNr: %d, success: %d, link: '%@'", job, buildNr, success, link];
}


- (void) dealloc {
	[job release];
	[link release];
	
	[super dealloc];
}

@end
