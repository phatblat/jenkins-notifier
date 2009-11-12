//
//  MyController.m
//  HudsonGrowl
//
//  Created by Benjamin Broll on 18.10.09.
//  Copyright 2009 BBG Entertainment GmbH. All rights reserved.
//

#import "MyController.h"

#import "HGrowl.h"
#import "HudsonResult.h"


@interface MyController (private)

- (void) parseRSS:(NSTimer *)theTimer;
- (void) openBrowserForResult:(HudsonResult*)result;
- (void) updateStatus:(NSDictionary*)results;

@end



@implementation MyController

@synthesize preferences, inputTextField, theMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	HGrowl* growl = [HGrowl instance];
	growl.clickDelegate = self;
	
	// Init icon in tray
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	
    theItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [theItem retain];

    [theItem setImage:[NSImage imageNamed:@"icon2.png"]];
	[theItem setHighlightMode:NO];
	
    [theItem setMenu:theMenu];
	
	// Init data objects
	lastResultsByJob = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
	menuItemsByJob = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
	
	// First parse
	[self parseRSS:nil];
	
	// Setup timer
	updateTimer = [[NSTimer scheduledTimerWithTimeInterval:60
													target:self
												  selector:@selector(parseRSS:)
												  userInfo:nil
												   repeats:YES] retain];
	
}

- (IBAction)clickSendGrowlMessage:(id)sender {
	
} 

- (void) growlNotificationWasClicked:(id)clickContext {
	NSString* job = (NSString*) clickContext;
	HudsonResult* result = [lastResultsByJob objectForKey:job];
	[self openBrowserForResult:result];
}

- (IBAction) clickOpenBuild:(id)sender {
	for (NSString* job in menuItemsByJob) {
		if (sender == [menuItemsByJob objectForKey:job]) {
			HudsonResult* result = [lastResultsByJob objectForKey:job];
			[self openBrowserForResult:result];
			break;
		}
	}
}

- (IBAction) clickPreferences:(id)sender {
	[preferences makeKeyAndOrderFront:sender];
}

- (IBAction) clickQuit:(id)sender {
	[[NSApplication sharedApplication] terminate: nil];
}


- (void) openBrowserForResult:(HudsonResult*)result {
	NSURL* url = [NSURL URLWithString:result.link];
	if (url != nil) [[NSWorkspace sharedWorkspace] openURL:url];
}


- (void) parseRSS: (NSTimer*) theTimer {
	// make sure we arent getting a cached response from Cocoa
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
		
	// load the URL into an NSXMLDocument and get the root element
	NSURL* feedURL = [NSURL URLWithString:@"http://localhost:8080/hudson/rssAll"];
	
	NSXMLDocument* DOM = [[NSXMLDocument alloc] initWithContentsOfURL:feedURL options:NSXMLNodeOptionsNone error:nil];
	NSXMLElement* root = [DOM rootElement];
	
	// iterate through all entries
	NSArray* nodes = [root nodesForXPath:@"entry" error:nil];
	NSMutableDictionary* resultsByJob = [NSMutableDictionary dictionary];
	
	for (NSXMLElement* entry in nodes) {
		NSString* title = [[[entry elementsForName:@"title"] objectAtIndex:0] stringValue];
		NSXMLElement* linkElement = (NSXMLElement*) [[entry elementsForName:@"link"] objectAtIndex:0];
		NSString* link = [[linkElement attributeForName:@"href"] stringValue];
		
		NSScanner* scanner = [NSScanner scannerWithString:title];
		NSString* sep = @"#";
		
		NSString* job;
		NSInteger buildNr;
		NSString* result;
		
		BOOL hasJob = [scanner scanUpToString:sep intoString:&job];
		[scanner scanString:sep intoString:NULL];
		BOOL hasNr = [scanner scanInteger:&buildNr];
		BOOL hasResult = [scanner scanUpToString:@"" intoString:&result];
		
		if (hasJob && hasNr && hasResult) {
			job = [job stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			BOOL success = [result isEqual:@"(SUCCESS)"];
			
			// only update in case job is unknown or build number is more recent
			// than what's currently stored
			if ([resultsByJob objectForKey:job] == nil
				|| [[resultsByJob objectForKey:job] buildNr] < buildNr) {
			
				HudsonResult* result = [HudsonResult resultWithJob:job buildNr:buildNr success:success link:link];
				[resultsByJob setObject:result forKey:job];
			}
		}
	}
	
	[DOM release];
	
	[self updateStatus:resultsByJob];
}


- (void) updateStatus:(NSDictionary*)results {
	HGrowl* growl = [HGrowl instance];
	
	// update new build results
	for (NSString* job in results) {
		HudsonResult* result = [results objectForKey:job];
		HudsonResult* lastResult = [lastResultsByJob objectForKey:job];
		NSMenuItem* indicator = [menuItemsByJob objectForKey:job];
		
		if (lastResult == nil || result.buildNr > lastResult.buildNr) {
			if (indicator == nil) {
				if ([menuItemsByJob count] == 0) {
					// reuse first entry in menu
					indicator = [theMenu itemAtIndex:0];
				} else {
					indicator = [theMenu insertItemWithTitle:@""
													  action:@selector(clickOpenBuild:)
											   keyEquivalent:@""
													 atIndex:0];
				}
				[menuItemsByJob setObject:indicator forKey:job];
			}
			[lastResultsByJob setObject:result forKey:job];
			
			if (result.success) {
				[indicator setImage:[NSImage imageNamed:@"menu_success.png"]];
				[indicator setTitle:[NSString stringWithFormat:@"%@ #%d", job, result.buildNr]];
				[indicator setEnabled:YES];
				
				[growl postNotificationWithName:GrowlHudsonSuccess
											job:job
										  title:job
									description:[NSString stringWithFormat:@"Build #%d successful!", result.buildNr]
										  image:[NSImage imageNamed:@"Clear Green Button.png"]];
			} else {
				[indicator setImage:[NSImage imageNamed:@"menu_failure.png"]];
				[indicator setTitle:[NSString stringWithFormat:@"%@ #%d", job, result.buildNr]];
				[indicator setEnabled:YES];
				
				[growl postNotificationWithName:GrowlHudsonFailure
											job:job
										  title:job
									description:[NSString stringWithFormat:@"Build #%d failed!", result.buildNr]
										  image:[NSImage imageNamed:@"Cancel Red Button.png"]];
			}
		}
	}
	
	// update overall status
	BOOL allSuccessful = YES;
	for (NSString* job in lastResultsByJob) {
		HudsonResult* result = [lastResultsByJob objectForKey:job];
		if (!result.success) {
			allSuccessful = NO;
			break;
		}
	}
	
	if (allSuccessful) {
		[theItem setImage:[NSImage imageNamed:@"icon2_success.png"]];
	} else {
		[theItem setImage:[NSImage imageNamed:@"icon2_failure.png"]];
	}
}


- (void) dealloc {
	[lastResultsByJob release];
	[menuItemsByJob release];
	[theItem release];
	[updateTimer release];
	
	[super dealloc];
}

@end
