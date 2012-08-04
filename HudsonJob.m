//
//  HudsonJob.m
//  HudsonGrowl
//
//  Created by Benjamin Broll on 13.11.10.
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

#import "HudsonJob.h"

#import "HudsonResult.h"


@implementation HudsonJob

@synthesize name, lastResult;


+ (HudsonJob*) jobWithName:(NSString*)name {
    return [[[self alloc] initWithName:name] autorelease];
}

- (id) initWithName:(NSString*)n {
    if ((self = [super init])) {
        self.name = n;
    }
    
    return self;
}

- (void)dealloc {
    self.name = nil;
    self.lastResult = nil;
    
    [super dealloc];
}

@end
