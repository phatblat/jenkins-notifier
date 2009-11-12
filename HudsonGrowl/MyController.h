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
