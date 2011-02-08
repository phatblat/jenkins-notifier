//
//  HudsonResult.m
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

#import "HudsonResult.h"


@implementation HudsonResult

@synthesize buildNr, success, link;


+(HudsonResult*)resultWithBuildNr:(NSInteger)nr success:(BOOL)success link:(NSString*)link {
	return [[[self alloc] initWithBuildNr:nr success:success link:link] autorelease];
}

-(id)initWithBuildNr:(NSInteger)nr success:(BOOL)s link:(NSString*)l {
	if ((self = [super init])) {
		buildNr = nr;
		success = s;
		link = [l retain];
	}
	
	return self;
}


- (NSString*) description {
	return [NSString stringWithFormat:@"buildNr: %d, success: %d, link: '%@'", buildNr, success, link];
}


- (void) dealloc {
	[link release];
	
	[super dealloc];
}

@end
