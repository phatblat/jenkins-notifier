//
//  NSString+ListContains.h
//  HudsonGrowl
//
//  Created by Benjamin Broll on 14.11.10.
//  Copyright 2010 NEXT Munich. The App Agency. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (ListContains)

- (BOOL) containsSubstringFromList:(NSArray *)list;

@end
