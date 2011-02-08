//
//  HudsonJob.h
//  HudsonGrowl
//
//  Created by Benjamin Broll on 13.11.10.
//  Copyright 2010 NEXT Munich. The App Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HudsonResult;

@interface HudsonJob : NSObject {
@private
    NSString* name;
    
    HudsonResult* lastResult;
}

@property (nonatomic, retain) NSString* name;

@property (nonatomic, retain) HudsonResult* lastResult;


+ (HudsonJob*) jobWithName:(NSString*)name;

- (id) initWithName:(NSString*)name;

@end
