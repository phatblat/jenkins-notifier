//
//  MyController.h
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

#import <Cocoa/Cocoa.h>

#import "SimplePing.h"


@interface MyController : NSObject <SimplePingDelegate> {
	
    // View
    // - Menu Bar
	NSMenu* theMenu;
	NSStatusItem* theItem;
	NSUInteger numDefaultMenuItems;
	NSMutableDictionary* menuItemsByJob;
    // - Preferences
	NSWindow* preferences;
	NSTextField *feedsTextField;
	NSTextField *whitelistTextField;
	NSTextField *blacklistTextField;
	NSButton *continuousNotificationCheckbox;
	NSButton *stickyNotificationCheckbox;
    
    // Model
    // - Settings
	NSArray *feeds;
	NSArray *whitelist;
	NSArray *blacklist;
	BOOL shouldUseContinuousNotifications;
	BOOL shouldUseStickyNotifications;
	NSTimeInterval pollIntervalInMinutes;
    // - Data
	NSMutableDictionary* lastResultsByJob;
    // - Host Information
	NSUInteger numConnectableHosts;
	NSUInteger numUnconnectableHosts;
    
    // Controlling
    // - Update Management
	NSTimer* updateTimer;
    // - Pinging
	SimplePing *currentPingTool;
}

@property (assign) IBOutlet NSWindow* preferences;
@property (assign) IBOutlet NSMenu* theMenu;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *feedsTextField;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *whitelistTextField;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *blacklistTextField;
@property (nonatomic, readwrite, retain) IBOutlet NSButton *stickyNotificationCheckbox;
@property (nonatomic, readwrite, retain) IBOutlet NSButton *continuousNotificationCheckbox;
@property (nonatomic, readwrite, retain) NSStatusItem *theItem;

- (IBAction) clickOpenBuild:(id)sender;
- (IBAction) clickPreferences:(id)sender;
- (IBAction) clickSave:(id)sender;
- (IBAction) clickQuit:(id)sender;

@end
