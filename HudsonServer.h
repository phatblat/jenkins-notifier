//
//  HudsonServer.h
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

#import <Foundation/Foundation.h>


@interface HudsonServer : NSObject {
@private
    NSString* name;
    
    NSURL* url;
    NSString* username;
    NSString* password;
    
    NSArray* whitelist;
    NSArray* blacklist;
    
    NSMutableArray* jobs;
}

@property (nonatomic, retain) NSString* name;

@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* password;

@property (nonatomic, retain) NSArray* whitelist;
@property (nonatomic, retain) NSArray* blacklist;

@property (readonly) NSMutableArray* jobs;

- (NSString*) apiCall;

- (NSArray*) filteredJobs;


+ (HudsonServer*) serverWithLegacyConnectionString:(NSString*)connectionString;
- (NSString*) legacyConnectionString;

@end
