//
//  HudsonServer.h
//  HudsonGrowl
//
//  Created by Benjamin Broll on 13.11.10.
//  Copyright 2010 NEXT Munich. The App Agency. All rights reserved.
//

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
