//
//  MyController.m
//  HudsonGrowl
//
//  Created by Benjamin Broll on 18.10.09.
//
//  This source code is licensed under the terms of the BSD license.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "MyController.h"
#import "HGrowl.h"
#import "HudsonResult.h"
#import <SystemConfiguration/SystemConfiguration.h>	
#import "CPingTool.h"

NSString *MyControllerFeedsKey = @"MyControllerFeedsKey";
NSString *MyControllerWhitelistKey = @"MyControllerWhitelistKey";
NSString *MyControllerBlacklistKey = @"MyControllerBlacklistKey";
NSString *MyControllerShouldUseStickyNotificationsKey = @"MyControllerShouldUseStickyNotificationsKey";
NSString *MyControllerShouldUseContinuousNotificationsKey = @"MyControllerShouldUseContinuousNotificationsKey";
NSString *MyControllerPollIntervalInMinutesKey = @"MyControllerPollIntervalInMinutesKey";


@interface MyController ()

- (void) parseRSS:(NSURL *)feedURL;
- (void) openBrowserForResult:(HudsonResult*)result;
- (void) updateStatus:(NSDictionary*)results;
- (void) handlePingNotification:(NSNotification *)notification;
- (void) handlePingNotificationOnMainThread:(NSNotification *)notification;
- (void) startUpdates:(NSTimer *)theTimer;

@property (nonatomic, readwrite, retain) NSArray *feeds;
@property (nonatomic, readwrite, retain) NSArray *whitelist;
@property (nonatomic, readwrite, retain) NSArray *blacklist;
@property (nonatomic, readwrite, retain) NSMutableDictionary *lastResultsByJob;
@property (nonatomic, readwrite, retain) NSMutableDictionary *menuItemsByJob;
@property (nonatomic, readwrite, assign) NSUInteger numDefaultMenuItems;
@property (nonatomic, readwrite, assign) NSUInteger numConnectableHosts;
@property (nonatomic, readwrite, assign) NSUInteger numUnconnectableHosts;
@property (nonatomic, readwrite, assign) BOOL shouldUseStickyNotifications;
@property (nonatomic, readwrite, assign) BOOL shouldUseContinuousNotifications;
@property (nonatomic, readwrite, retain) NSTimer *updateTimer;
@property (nonatomic, readwrite, assign) NSTimeInterval pollIntervalInMinutes;
@property (nonatomic, readwrite, retain) CPingTool *currentPingTool;

@end


@implementation MyController

@synthesize preferences, theMenu, feedsTextField, whitelistTextField, blacklistTextField, feeds, whitelist, blacklist, theItem, numDefaultMenuItems;
@synthesize lastResultsByJob, menuItemsByJob, stickyNotificationCheckbox, shouldUseStickyNotifications, continuousNotificationCheckbox, shouldUseContinuousNotifications;
@synthesize numConnectableHosts, numUnconnectableHosts, updateTimer, pollIntervalInMinutes, currentPingTool;

- (NSString *)commaSeparatedListFromStringArray:(NSArray *)stringArray
{
	NSString *commaSeparatedList = @"";
	
	for (NSString *string in stringArray)
	{
		if ([commaSeparatedList length] > 0)
		{
			commaSeparatedList = [NSString stringWithFormat:@"%@, ", commaSeparatedList];
		}
		commaSeparatedList = [NSString stringWithFormat:@"%@%@", commaSeparatedList, string];
	}
	
	return commaSeparatedList;
}

- (NSArray *)stringArrayFromCommaSeparatedList:(NSString *)list
{
	NSScanner *scanner = [NSScanner scannerWithString:list];
	NSString *sep = @",";
	NSString *element;
	NSMutableArray *stringArray = [[[NSMutableArray alloc] init] autorelease];
	
	// Keep reading from the list until we're done
	while ( [scanner scanUpToString:sep intoString:&element] )
	{
		[scanner scanString:sep intoString:NULL];
		element = [element stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[stringArray addObject:[[element copy] autorelease]];
	}
	
	return stringArray;
}

- (NSMenuItem *)insertEmptyMenuItem
{
	NSMenuItem *emptyMenuItem = [theMenu insertItemWithTitle:@"Waiting For Result ..."
												  action:nil
										   keyEquivalent:@""
												 atIndex:0];
	[emptyMenuItem setEnabled:NO];
	return emptyMenuItem;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	HGrowl* growl = [HGrowl instance];
	growl.clickDelegate = self;
	
	// Init icon in tray
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	
    theItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [theItem retain];
    [theItem setImage:[NSImage imageNamed:@"icon2.png"]];
	[theItem setHighlightMode:YES];
    [theItem setMenu:theMenu];
	
	self.numDefaultMenuItems = [self.theMenu numberOfItems];
	[self insertEmptyMenuItem];
	
	// Init data objects
	lastResultsByJob = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
	menuItemsByJob = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
	
	// Read settings from disk, set to default values if needed
	self.feeds = [[NSUserDefaults standardUserDefaults] stringArrayForKey:MyControllerFeedsKey];
	self.whitelist = [[NSUserDefaults standardUserDefaults] stringArrayForKey:MyControllerWhitelistKey];
	self.blacklist = [[NSUserDefaults standardUserDefaults] stringArrayForKey:MyControllerBlacklistKey];
	BOOL stickyNotificationsHasValue = [[NSUserDefaults standardUserDefaults] objectForKey:MyControllerShouldUseStickyNotificationsKey] == nil ? NO: YES;
	BOOL continuousNotificationsHasValue = [[NSUserDefaults standardUserDefaults] objectForKey:MyControllerShouldUseContinuousNotificationsKey] == nil ? NO : YES;
	BOOL pollIntervalInMinutesHasValue = [[NSUserDefaults standardUserDefaults] objectForKey:MyControllerPollIntervalInMinutesKey] == nil ? NO : YES;
	self.shouldUseStickyNotifications = stickyNotificationsHasValue ? [[NSUserDefaults standardUserDefaults] boolForKey:MyControllerShouldUseStickyNotificationsKey] : YES; // default yes
	self.shouldUseContinuousNotifications = continuousNotificationsHasValue ? [[NSUserDefaults standardUserDefaults] boolForKey:MyControllerShouldUseContinuousNotificationsKey] : NO; // default to no
	self.pollIntervalInMinutes = pollIntervalInMinutesHasValue ? [[NSUserDefaults standardUserDefaults] floatForKey:MyControllerPollIntervalInMinutesKey] : 1.0f; // default to 1 minute
			
	// Start looking for valid servers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePingNotificationOnMainThread:) name:TXPingToolDidReceivePacketNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePingNotificationOnMainThread:) name:TXPingToolDidLosePacketNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePingNotificationOnMainThread:) name:TXPingToolDidFailNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePingNotificationOnMainThread:) name:TXPingToolDidFinishNotification object:nil];

	
	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:self.pollIntervalInMinutes * 60.0f
														target:self
													  selector:@selector(startUpdates:)
													  userInfo:nil
													   repeats:YES];
	[self startUpdates:self.updateTimer];
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
	// Fill in the preference pane with the archived lists
	self.feedsTextField.stringValue = [self commaSeparatedListFromStringArray:self.feeds];
	self.whitelistTextField.stringValue = [self commaSeparatedListFromStringArray:self.whitelist];
	self.blacklistTextField.stringValue = [self commaSeparatedListFromStringArray:self.blacklist];
	self.stickyNotificationCheckbox.state = self.shouldUseStickyNotifications ? NSOnState : NSOffState;
	self.continuousNotificationCheckbox.state = self.shouldUseContinuousNotifications ? NSOnState : NSOffState;

	// Prepare the window for display
	[preferences center];
	[preferences setLevel:NSFloatingWindowLevel]; // Not sure what the right level is, but the default NormalWindow level leaves the preferences buried behind other apps
	[preferences makeKeyAndOrderFront:sender];
}

- (IBAction) clickQuit:(id)sender {
	[[NSApplication sharedApplication] terminate: nil];
}

- (IBAction) clickSave:(id)sender {
	// Parse each text field into an array, save to disk and local vars
	self.feeds = [self stringArrayFromCommaSeparatedList:self.feedsTextField.stringValue];
	self.whitelist = [self stringArrayFromCommaSeparatedList:self.whitelistTextField.stringValue];	
	self.blacklist = [self stringArrayFromCommaSeparatedList:self.blacklistTextField.stringValue];
	self.shouldUseStickyNotifications = ([self.stickyNotificationCheckbox state] == NSOnState) ? YES : NO;
	self.shouldUseContinuousNotifications = ([self.continuousNotificationCheckbox state] == NSOnState) ? YES : NO;
	// TODO: Add UI control for poll timer
	// self.pollIntervalInMinutes = ([self.pollIntervalInMinutesTextField.stringValue floatValue]  // error checking range, int to float, etc
	
	// Save defaults to disk
	[[NSUserDefaults standardUserDefaults] setObject:self.feeds forKey:MyControllerFeedsKey];
	[[NSUserDefaults standardUserDefaults] setObject:self.whitelist forKey:MyControllerWhitelistKey];
	[[NSUserDefaults standardUserDefaults] setObject:self.blacklist forKey:MyControllerBlacklistKey];
	[[NSUserDefaults standardUserDefaults] setBool:self.shouldUseStickyNotifications forKey:MyControllerShouldUseStickyNotificationsKey];
	[[NSUserDefaults standardUserDefaults] setBool:self.shouldUseContinuousNotifications forKey:MyControllerShouldUseContinuousNotificationsKey];
	[[NSUserDefaults standardUserDefaults] setFloat:self.pollIntervalInMinutes forKey:MyControllerPollIntervalInMinutesKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[preferences close];
	
	// Clear out menu items, as they may have changed.  Set up for a refresh.
	NSUInteger numMenuItems = [self.theMenu numberOfItems] - self.numDefaultMenuItems; // there's probably a better way to do this
	for (int menuItemIndex = 0; menuItemIndex < numMenuItems; menuItemIndex++)
	{
		[self.theMenu removeItemAtIndex:0];
	}
	[self insertEmptyMenuItem];
	
	// Reinit data objects
	[lastResultsByJob removeAllObjects];
	[menuItemsByJob removeAllObjects];
			
	// Update build status
	[self.updateTimer invalidate];
	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:self.pollIntervalInMinutes * 60.0f
														target:self
													  selector:@selector(startUpdates:)
													  userInfo:nil
													   repeats:YES];
	[self startUpdates:self.updateTimer];	
}

- (void) openBrowserForResult:(HudsonResult*)result {
	NSURL* url = [NSURL URLWithString:result.link];
	if (url != nil) [[NSWorkspace sharedWorkspace] openURL:url];
}

- (BOOL)job:(NSString *)job containsSubstringFromList:(NSArray *)list
{
	BOOL wasSubstringFound = NO;
	
	for (NSString *substring in list)
	{
		if ([substring length] > 0)
		{
			NSRange range = [job rangeOfString:substring];
			if (range.location != NSNotFound)
			{
				wasSubstringFound = YES;
				break;
			}
		}
	}
	
	return wasSubstringFound;
}

- (void) parseRSS:(NSURL *)feedURL {
	// make sure we arent getting a cached response from Cocoa
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	NSMutableDictionary* resultsByJob = [NSMutableDictionary dictionaryWithCapacity:1];
	// load the URL into an NSXMLDocument and get the root element	
	NSXMLDocument* DOM = [[NSXMLDocument alloc] initWithContentsOfURL:feedURL options:NSXMLNodeOptionsNone error:nil];
	NSXMLElement* root = [DOM rootElement];
	
	// iterate through all entries
	NSArray* nodes = [root nodesForXPath:@"entry" error:nil];
	
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
		
		// Only save the result if the job name is 1) on the whitelist and not on the blacklist, 2) there is no whitelist, and it is not on the blacklist		
		[scanner scanString:sep intoString:NULL];
		BOOL hasNr = [scanner scanInteger:&buildNr];
		BOOL hasResult = [scanner scanUpToString:@"" intoString:&result];
		
		BOOL isOnWhitelist = [self.whitelist count] == 0 || [self job:job containsSubstringFromList:self.whitelist];
		BOOL isOnBlacklist = [self.blacklist count] > 0 && [self job:job containsSubstringFromList:self.blacklist];
		
		if (hasJob && hasNr && hasResult && isOnWhitelist && !isOnBlacklist) {
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
	for (NSString *job in results) {
		HudsonResult *result = [results objectForKey:job];
		HudsonResult* lastResult = [lastResultsByJob objectForKey:job];
		NSMenuItem* indicator = [menuItemsByJob objectForKey:job];
		
		if (lastResult == nil || result.buildNr > lastResult.buildNr) {
			if (indicator == nil) {
				if ([menuItemsByJob count] == 0) {
					// reuse first entry in menu
					indicator = [theMenu itemAtIndex:0];
					[indicator setEnabled:YES];
					[indicator setAction:@selector(clickOpenBuild:)];
				} 
				else 
				{
					NSArray *menuItems = [theMenu itemArray];
					NSEnumerator *menuIterator = [menuItems objectEnumerator];
					NSMenuItem *menuItem;
					
					// Search through menu items and insert alphabetically
					while ( (menuItem = [menuIterator nextObject]) && ![menuItem isSeparatorItem]) {
						if ( [job localizedCaseInsensitiveCompare:[menuItem title]] != NSOrderedDescending )
							break;
					}
				
					indicator = [theMenu insertItemWithTitle:@""
													  action:@selector(clickOpenBuild:)
											   keyEquivalent:@""
													 atIndex:[theMenu indexOfItem:menuItem]];
				}
				[menuItemsByJob setObject:indicator forKey:job];
			}
			
			if (result.success) {
				[indicator setImage:[NSImage imageNamed:@"menu_success.png"]];
				[indicator setTitle:[NSString stringWithFormat:@"%@ #%d", job, result.buildNr]];
				[indicator setEnabled:YES];
			
				// Depending on settings: Only post the notification if different than last time OR post on all builds
				if (lastResult == nil || (self.shouldUseContinuousNotifications && result.success == lastResult.success))
				{
					[growl postNotificationWithName:GrowlHudsonSuccess
												job:job
											  title:job
										description:[NSString stringWithFormat:@"Build successful (%d)", result.buildNr]
											  image:[NSImage imageNamed:@"Clear Green Button.png"]
										   isSticky:NO];

				}
				else if (result.success != lastResult.success)
				{
					[growl postNotificationWithName:GrowlHudsonSuccess
												job:job
											  title:job
										description:[NSString stringWithFormat:@"Build has been restored (%d)", result.buildNr]
											  image:[NSImage imageNamed:@"Clear Green Button.png"]
										   isSticky:(lastResult != nil && self.shouldUseStickyNotifications)];
				}
				
			} else {
				[indicator setImage:[NSImage imageNamed:@"menu_failure.png"]];
				[indicator setTitle:[NSString stringWithFormat:@"%@ #%d", job, result.buildNr]];
				[indicator setEnabled:YES];

				if (lastResult == nil || self.shouldUseContinuousNotifications || (result.success != lastResult.success))
				{
					[growl postNotificationWithName:GrowlHudsonFailure
												job:job
											  title:job
										description:[NSString stringWithFormat:@"Build failed (%d)", result.buildNr]
											  image:[NSImage imageNamed:@"Cancel Red Button.png"]
										   isSticky:(lastResult != nil && (result.success != lastResult.success && self.shouldUseStickyNotifications))];
				}
			}
			
			
			// Replace at the end, so we don't end up accessing a non-existent object
			[lastResultsByJob setObject:result forKey:job];
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
	
	// TODO: change default menu item to "No Results Found" when the server is connected but the lists prevent any builds from showing
	// TODO: change icon to icon2.png in the case when no results are shown
	if (allSuccessful) {
		[theItem setImage:[NSImage imageNamed:@"icon2_success.png"]];
	} else {
		[theItem setImage:[NSImage imageNamed:@"icon2_failure.png"]];
	}
}

- (BOOL)isHostReachable:(NSString *)hostname
{	
	Boolean isHostReachable = false;
	
	if ([hostname length] > 0)
	{
		const char *hostNameC = [hostname cStringUsingEncoding:NSASCIIStringEncoding];
		SCNetworkReachabilityRef target;
		SCNetworkConnectionFlags flags = 0;
		target = SCNetworkReachabilityCreateWithName(NULL, hostNameC);
		isHostReachable = SCNetworkReachabilityGetFlags(target, &flags);
		CFRelease(target);
	}
		
	return isHostReachable ? YES : NO;
}

- (BOOL)pingFeedServer:(NSString *)feed
{
	NSLog(@"### attempting to connect to feed: %@", feed);
	
	BOOL initiatedPing = NO;
	NSString *hostname = [[NSURL URLWithString:feed] host];
	BOOL isHostReachable = [hostname length] > 0 && [self isHostReachable:hostname];

	// Check if we have an outbound network connection (host is reachable) & and if there is an address mapping
	if (isHostReachable)
	{	
		NSHost *host = [NSHost hostWithName:hostname];
		if (host != nil)
		{
			// Next ping it to see if it responds
			self.currentPingTool = [[[CPingTool alloc] init] autorelease];
			[self.currentPingTool setHost:host];
			[self.currentPingTool setTimeout:0.2f];
			[self.currentPingTool setPingCount:1];
			[self.currentPingTool ping];
			initiatedPing = YES;
		}
	}
	
	return initiatedPing;
}

- (void)nextUpdate
{
	BOOL initiatedPing = NO;
	NSUInteger numFeeds = [feeds count];
	NSUInteger numServersTested = self.numConnectableHosts + self.numUnconnectableHosts;
	
	// Cycle through feeds until we successfully initiate a ping.  Once initiated, wait for the notification.
	while ( (numServersTested < numFeeds) && 
		   !(initiatedPing = [self pingFeedServer:[feeds objectAtIndex:numServersTested]]) ) 
	{
		// TODO: Gray out menu items associated with this host (some hosts may be connected, while others are not)
		self.numUnconnectableHosts++;
		numServersTested = self.numConnectableHosts + self.numUnconnectableHosts;
	}
	
	// If we were unable to successfully initiate a ping, then we've finished our list of feeds. Update the status menu if needed. 
	if (!initiatedPing)
	{
		// TODO: Add partial connection icon in status menu, if only some servers are offline
		if (self.numUnconnectableHosts == [self.feeds count])
		{
			// Disconnected icon
			[theItem setImage:[NSImage imageNamed:@"icon2.png"]];
		}
		
		NSLog(@"### finished");
	}
}

- (void)startUpdates:(NSTimer *)theTimer
{
	// reset everything, prepare for updates
	self.numConnectableHosts = 0;
	self.numUnconnectableHosts = 0;	
	
	// kick off the updates
	[self nextUpdate];
}

- (void)handlePingNotificationOnMainThread:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(handlePingNotification:) withObject:notification waitUntilDone:YES];
}

- (void)handlePingNotification:(NSNotification *)notification
{	
	NSString *host = [[[notification userInfo] objectForKey:@"host"] name];

	if ([[notification name] isEqualToString:TXPingToolDidFinishNotification])
	{		
		// Continue with the updates, because we were paused while waiting for the notification to finish
		[self nextUpdate];
	}
	else if ([[notification name] isEqualToString:TXPingToolDidReceivePacketNotification]) 
	{
		NSLog(@"### received response from host: %@", host);
		
		// Parse the RSS feed
		NSString *feed = [feeds objectAtIndex:(self.numConnectableHosts + self.numUnconnectableHosts)];
		NSURL *feedURL = [NSURL URLWithString:feed];
		[self parseRSS:feedURL];
		
		self.numConnectableHosts++;
	}
	else if ([[notification name] isEqualToString:TXPingToolDidFailNotification] ||
			 [[notification name] isEqualToString:TXPingToolDidLosePacketNotification])
	{
		BOOL wasPingLost = ([[notification userInfo] objectForKey:@"packetSequenceNumber"] != nil);
		if (wasPingLost)
		{
			NSLog(@"### lost packet to host: %@", host);
		}
		else
		{
			NSLog(@"### pingtool bailed attempting to reach host: %@", host);
		}
		
		// TODO: Gray out menu items associated with this host
		self.numUnconnectableHosts++;		
	} 	
}

- (void) dealloc {
	[lastResultsByJob release]; lastResultsByJob = nil;
	[menuItemsByJob release]; menuItemsByJob = nil;
	[theItem release]; theItem = nil;
	[preferences release]; preferences = nil;
	[theMenu release]; theMenu = nil;
	[feedsTextField release]; feedsTextField = nil;
	[whitelistTextField release]; whitelistTextField = nil;
	[blacklistTextField release]; blacklistTextField = nil;
	[feeds release]; feeds = nil;
	[whitelist release]; whitelist = nil;
	[blacklist release]; blacklist = nil;
	[stickyNotificationCheckbox release]; stickyNotificationCheckbox = nil;
	[continuousNotificationCheckbox release]; continuousNotificationCheckbox = nil;
	[currentPingTool release]; currentPingTool = nil;
	
	[updateTimer invalidate]; updateTimer = nil;	
	
	[super dealloc];
}

@end
