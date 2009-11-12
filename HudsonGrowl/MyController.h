//
//  MyController.h
//  HudsonGrowl
//
//  Created by Benjamin Broll on 18.10.09.
//  Copyright 2009 BBG Entertainment GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HudsonResult;

@interface MyController : NSObject {
	
	NSWindow* preferences;
	
	NSTextField* inputTextField;
	NSMenu* theMenu;
	
	NSStatusItem* theItem;
	
	NSTimer* updateTimer;
	
	NSMutableDictionary* lastResultsByJob;
	NSMutableDictionary* menuItemsByJob;
}

@property (assign) IBOutlet NSWindow* preferences;
@property (assign) IBOutlet NSTextField* inputTextField;
@property (assign) IBOutlet NSMenu* theMenu;

- (IBAction) clickSendGrowlMessage:(id)sender;

- (IBAction) clickOpenBuild:(id)sender;
- (IBAction) clickPreferences:(id)sender;
- (IBAction) clickQuit:(id)sender;

@end
