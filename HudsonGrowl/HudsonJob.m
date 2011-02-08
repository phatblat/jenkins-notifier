//
//  HudsonJob.m
//  HudsonGrowl
//
//  Created by Benjamin Broll on 13.11.10.
//  Copyright 2010 NEXT Munich. The App Agency. All rights reserved.
//

#import "HudsonJob.h"

#import "HudsonResult.h"


@implementation HudsonJob

@synthesize name, lastResult;


+ (HudsonJob*) jobWithName:(NSString*)name {
    return [[[self alloc] initWithName:name] autorelease];
}

- (id) initWithName:(NSString*)n {
    if ((self = [super init])) {
        self.name = n;
    }
    
    return self;
}

- (void)dealloc {
    self.name = nil;
    self.lastResult = nil;
    
    [super dealloc];
}

@end
