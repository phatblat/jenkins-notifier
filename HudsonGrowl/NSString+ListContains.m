//
//  NSString+ListContains.m
//  HudsonGrowl
//
//  Created by Benjamin Broll on 14.11.10.
//  Copyright 2010 NEXT Munich. The App Agency. All rights reserved.
//

#import "NSString+ListContains.h"


@implementation NSString (ListContains)

- (BOOL) containsSubstringFromList:(NSArray *)list
{
	BOOL wasSubstringFound = NO;
	
	for (NSString *substring in list)
	{
		if ([substring length] > 0)
		{
			NSRange range = [self rangeOfString:substring];
			if (range.location != NSNotFound)
			{
				wasSubstringFound = YES;
				break;
			}
		}
	}
	
	return wasSubstringFound;
}

@end
