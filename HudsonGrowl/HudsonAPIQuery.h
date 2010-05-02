//
//  HudsonAPIQuery.h
//  HudsonGrowl
//
//  Created by Benjamin Broll on 02.05.10.
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

@class HudsonAPIQuery;


@protocol HudsonAPIQueryDelegate

- (void) query:(HudsonAPIQuery*)query completedWithXML:(NSString*)xml;
- (void) query:(HudsonAPIQuery*)query didFailWithError:(NSError*)error;

@end



@interface HudsonAPIQuery : NSObject {

	id<HudsonAPIQueryDelegate,NSObject> delegate;
	
	NSString* query;
	NSString* username;
	NSString* password;
	
	NSURLConnection* connection;
	NSError* error;
	NSMutableData* responseData;
	NSString* responseText;
	
	BOOL connectionDidFinishLoading;
	
}

+ (NSString*) synchronousQuery:(NSString*)apiCall;
+ (NSString*) synchronousQuery:(NSString*)apiCall user:(NSString*)user password:(NSString*)pass;

- (id) initWithQuery:(NSString*)apiCall user:(NSString*)user password:(NSString*)pass delegate:(id<HudsonAPIQueryDelegate,NSObject>)d;
- (void) start;

@end
