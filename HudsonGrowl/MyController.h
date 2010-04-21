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

@class HudsonResult, CPingTool;

@interface MyController : NSObject {
	
	NSWindow* preferences;	
	NSTextField *feedsTextField;
	NSTextField *whitelistTextField;
	NSTextField *blacklistTextField;
	NSArray *feeds;
	NSArray *whitelist;
	NSArray *blacklist;
	NSMenu* theMenu;
	NSStatusItem* theItem;
	NSTimer* updateTimer;
	NSUInteger numDefaultMenuItems;	
	NSMutableDictionary* lastResultsByJob;
	NSMutableDictionary* menuItemsByJob;
	NSButton *continuousNotificationCheckbox;
	BOOL shouldUseContinuousNotifications;
	NSButton *stickyNotificationCheckbox;
	BOOL shouldUseStickyNotifications;
	NSUInteger numConnectableHosts;
	NSUInteger numUnconnectableHosts;
	NSTimeInterval pollIntervalInMinutes;
	CPingTool *currentPingTool;
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
