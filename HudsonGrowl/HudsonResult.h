//
//  HudsonResult.h
//  HudsonGrowl
//
//  Created by Benjamin Broll on 19.10.09.
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


@interface HudsonResult : NSObject {
	NSString* job;
	int buildNr;
	BOOL success;
	
	NSString* link;
}

@property (readonly) NSString* job;
@property (readonly) int buildNr;
@property (readonly) BOOL success;
@property (readonly) NSString* link;

+(HudsonResult*)resultWithJob:(NSString*)job buildNr:(int)nr success:(BOOL)success link:(NSString*)link;
-(id)initWithJob:(NSString*)job buildNr:(int)nr success:(BOOL)success link:(NSString*)link;

@end
