//
//  MDServer.h
//  HaloMD
//
//  Created by null on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDServer : NSObject
{
	NSString *name;
	NSString *map;
	NSString *variant;
	NSString *gametype;
	NSString *scoreLimit;
	NSString *teamPlay;
	NSString *dedicated;
	NSString *ipAddress;
	NSArray *players;
	int portNumber;
	int ping;
	int currentNumberOfPlayers;
	int maxNumberOfPlayers;
	BOOL passwordProtected;
	BOOL valid;
	
	NSDate *lastUpdatedDate;
	
	int connectionChances;
}

@property (copy, readwrite) NSString *name;
@property (copy, readwrite) NSString *map;
@property (copy, readwrite) NSString *variant;
@property (copy, readwrite) NSString *gametype;
@property (copy, readwrite) NSString *scoreLimit;
@property (copy, readwrite) NSString *teamPlay;
@property (copy, readwrite) NSString *ipAddress;
@property (copy, readwrite) NSArray *players;
@property (copy, readwrite) NSString *dedicated;
@property (readwrite) int portNumber;
@property (readwrite) int ping;
@property (readwrite) int currentNumberOfPlayers;
@property (readwrite) int maxNumberOfPlayers;
@property (readwrite) BOOL passwordProtected;

@property (readwrite) BOOL valid;

@property (retain, readwrite) NSDate *lastUpdatedDate;

+ (NSDictionary *)formalizedMapsDictionary;

- (void)useConnectionChance;
- (void)resetConnectionChances;
- (BOOL)outOfConnectionChances;
- (NSString *)invalidDescription;
- (NSString *)formalizedMap;

@end
