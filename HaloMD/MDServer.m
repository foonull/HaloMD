//
//  MDServer.m
//  HaloMD
//
//  Created by null on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
