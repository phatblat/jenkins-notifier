//
//  HudsonServer.m
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

#import "HudsonServer.h"

#import "HudsonJob.h"
#import "NSString+ListContains.h"


@implementation HudsonServer

@synthesize name, url, username, password, whitelist, blacklist, jobs;


- (NSString*) apiCall {
    return [NSString stringWithFormat:@"%@/api/xml?depth=2&xpath=/*/job/lastBuild&wrapper=hudson", [self.url absoluteString]];
}

- (NSArray*) filteredJobs {
    NSMutableArray* result = [NSMutableArray array];
    
    for (HudsonJob* job in self.jobs) {
        // Only return the job if its name is
        // 1) on the whitelist and not on the blacklist
        // 2) there is no whitelist, and it is not on the blacklist
        BOOL isOnWhitelist = [self.whitelist count] == 0 || [job.name containsSubstringFromList:self.whitelist];
        BOOL isOnBlacklist = [self.blacklist count] > 0 && [job.name containsSubstringFromList:self.blacklist];
        
        if (isOnWhitelist && !isOnBlacklist) [result addObject:job];
    }
    
    return result;
}


+ (HudsonServer*) serverWithLegacyConnectionString:(NSString*)connectionString {
    // try to find user / pass in hudsonInstall string
	NSString* user = nil;
	NSString* pass = nil;
	NSRange rangeOfLogin = [connectionString rangeOfString:@"@"];
	if (rangeOfLogin.location != NSNotFound) {
		rangeOfLogin.location++;
		rangeOfLogin.length = [connectionString length]-rangeOfLogin.location;
		
		NSString* login = [connectionString substringWithRange:rangeOfLogin];
		connectionString = [connectionString substringToIndex:rangeOfLogin.location-1];
		
		NSRange rangeOfSeparator = [login rangeOfString:@":"];
		user = [login substringToIndex:rangeOfSeparator.location];
		pass = [login substringFromIndex:rangeOfSeparator.location+rangeOfSeparator.length];
	}
    
    HudsonServer* server = [[[HudsonServer alloc] init] autorelease];
    
    server.url = [NSURL URLWithString:connectionString];
    server.name = [server.url host];
    server.username = user;
    server.password = pass;
    
    return server;
}

- (NSString*) legacyConnectionString {
    if (username != nil && password != nil) {
        return [NSString stringWithFormat:@"%@@%@:%@", [url absoluteString], username, password];
    } else {
        return [url absoluteString];
    }
}


- (id)init {
    if ((self = [super init])) {
        jobs = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    self.name = nil;
    self.url = nil;
    self.username = nil;
    self.password = nil;
    self.whitelist = nil;
    self.blacklist = nil;
    [jobs release];
    
    [super dealloc];
}

@end
