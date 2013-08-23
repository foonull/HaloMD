/*
 * Copyright (c) 2013, Null <foo.null@yahoo.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this
 * list of conditions and the following disclaimer in the documentation and/or
 * other materials provided with the distribution.
 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//
//  MDServer.h
//  HaloMD
//
//  Created by null on 1/26/12.
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
