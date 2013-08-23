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
//  MDServer.m
//  HaloMD
//
//  Created by null on 1/26/12.
//

#import "MDServer.h"
#import "MDModsController.h"

@implementation MDServer

@synthesize name;
@synthesize map;
@synthesize variant;
@synthesize gametype;
@synthesize scoreLimit;
@synthesize teamPlay;
@synthesize ipAddress;
@synthesize players;
@synthesize portNumber;
@synthesize ping;
@synthesize currentNumberOfPlayers;
@synthesize maxNumberOfPlayers;
@synthesize passwordProtected;
@synthesize dedicated;

@synthesize valid;

@synthesize lastUpdatedDate;

+ (NSDictionary *)formalizedMapsDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"Blood Gulch", @"bloodgulch",
			@"Battle Creek", @"beavercreek",
			@"Rat Race", @"ratrace",
			@"Hang 'Em High", @"hangemhigh",
			@"Chill Out", @"chillout",
			@"Derelict", @"carousel",
			@"Boarding Action", @"boardingaction",
			@"Chiron TL-34", @"putput",
			@"Ice Fields", @"icefields",
			@"Death Island", @"deathisland",
			@"Danger Canyon", @"dangercanyon",
			@"Damnation", @"damnation",
			@"Gephyrophobia", @"gephyrophobia",
			@"Infinity", @"infinity",
			@"Longest", @"longest",
			@"Prisoner", @"prisoner",
			@"Sidewinder", @"sidewinder",
			@"Timberland", @"timberland",
			@"Wizard", @"wizard",
			// mods included by default
			@"Crossing", @"crossing",
			@"Barrier", @"barrier",
			nil];
}

#define INITIAL_NUMBER_OF_CHANCES 5

- (id)init
{
	self = [super init];
	if (self)
	{
		[self resetConnectionChances];
	}
	return self;
}

- (void)resetConnectionChances
{
	connectionChances = INITIAL_NUMBER_OF_CHANCES;
}

- (void)useConnectionChance
{
	connectionChances--;
}

- (BOOL)outOfConnectionChances
{
	return (connectionChances <= 0);
}

- (NSString *)invalidDescription
{
	NSMutableString *description = [NSMutableString string];
	int questionMarksCounter;
	for (questionMarksCounter = 0; questionMarksCounter < INITIAL_NUMBER_OF_CHANCES - connectionChances + 1; questionMarksCounter++)
	{
		[description appendString:@"?"];
	}
	
	return description;
}

- (NSString *)formalizedMap
{
	NSString *formalizedMap = [[[self class] formalizedMapsDictionary] objectForKey:[self map]];
	if (!formalizedMap)
	{
		// It's a mod
		formalizedMap = [[[[MDModsController modsController] modListDictionary] objectForKey:[self map]] name];
	}
	
	if (!formalizedMap)
	{
		formalizedMap = [self map];
	}
	
	return formalizedMap;
}

@end
