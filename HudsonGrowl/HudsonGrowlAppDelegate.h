//
//  HudsonGrowlAppDelegate.h
//  HudsonGrowl
//
//  Created by Benjamin Broll on 18.10.09.
//  Copyright 2009 BBG Entertainment GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HudsonGrowlAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
