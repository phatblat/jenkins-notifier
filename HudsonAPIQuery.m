//
//  HudsonAPIQuery.m
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

#import "HudsonAPIQuery.h"

#import "NSString+Base64.h"


@implementation HudsonAPIQuery

#pragma mark Synchronous Operation

+ (NSString*) synchronousQuery:(NSString*)apiCall {
	return [HudsonAPIQuery synchronousQuery:apiCall user:nil password:nil];
}

+ (NSString*) synchronousQuery:(NSString*)apiCall user:(NSString*)user password:(NSString*)pass {
	HudsonAPIQuery* q = [[HudsonAPIQuery alloc] initWithQuery:apiCall user:user password:pass delegate:nil];
	[q start];
	
	// Now wait for response
	NSRunLoop *theRL = [NSRunLoop currentRunLoop];
	while (!q->connectionDidFinishLoading && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
	
	NSString* xml = [q->responseText retain];
	[q release];
	
	return [xml autorelease];
}


#pragma mark Asynchronous Operation

- (id) initWithQuery:(NSString*)apiCall user:(NSString*)user
			password:(NSString*)pass delegate:(id<HudsonAPIQueryDelegate,NSObject>)d {
	
	if ((self = [super init])) {
		delegate = [d retain];
		query = [apiCall copy];
		username = [user copy];
		password = [pass copy];
	}
	
	return self;
}

- (void) dealloc {
	[responseText release];
	[responseData release];
	[error release];
	[connection release];
	
	[delegate release];
	[query release];
	[username release];
	[password release];
	
	[super dealloc];
}

- (void) start {
	// prepare the request
	NSURL* url = [NSURL URLWithString:query];
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
	
	// we have to manually set the authorization field since Hudson does not
	// send an authentication challenge
	// (http://wiki.hudson-ci.org/display/HUDSON/Authenticating+scripted+clients)
	NSString* format = [NSString stringWithFormat:@"%@:%@", username, password];
	NSString* auth = [NSString stringWithFormat:@"Basic %@", [format base64String]];
	[req addValue:auth forHTTPHeaderField:@"Authorization"];
	[req setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	
	// open the connection
	connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[connection start];	
}


#pragma mark NSURLConnection Callbacks

- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

-(void)connection:(NSURLConnection *)conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	// this code will accept any https servers - even if their certificate fails to validate

	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		//if ([trustedHosts containsObject:challenge.protectionSpace.host]) {
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
		//}
	} else if ([challenge previousFailureCount] == 0) {
		NSURLCredential *newCredential;
		newCredential=[NSURLCredential credentialWithUser:username
												 password:password
											  persistence:NSURLCredentialPersistenceForSession];
		[[challenge sender] useCredential:newCredential
			   forAuthenticationChallenge:challenge];
	} else {
		[[challenge sender] cancelAuthenticationChallenge:challenge];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Authentication Error" forKey:NSLocalizedDescriptionKey];
		NSError *authError = [NSError errorWithDomain:@"Connection Authentication" code:0 userInfo:userInfo];
		[self connection:conn didFailWithError:authError];
	}
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)urlResponse {
	/*NSHTTPURLResponse *httpResponse;
	if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
		httpResponse = (NSHTTPURLResponse *) urlResponse;
	} else {
		httpResponse = nil;
	}
	
	NSLog(@"ResponseStatus: %u\n", [httpResponse statusCode]);
	NSLog(@"ResponseHeaders:\n%@", [httpResponse allHeaderFields]);*/
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
	if (responseData == nil) {
		responseData = [data mutableCopy];
	} else {
		[responseData appendData:data];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {	
	connectionDidFinishLoading = YES;
	
	// convert data
	NSString* xml = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
	// try a fall-back encoding
	if (xml == nil) xml = [[[NSString alloc] initWithData:responseData encoding:NSWindowsCP1252StringEncoding] autorelease];

	if (delegate != nil) {
		[delegate query:self completedWithXML:xml];
	} else {
		responseText = [xml retain];
	}
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)e {	
	connectionDidFinishLoading = YES;
	if (delegate != nil) {
		[delegate query:self didFailWithError:error];
	} else {
		error = [e retain];
	}
}


@end
