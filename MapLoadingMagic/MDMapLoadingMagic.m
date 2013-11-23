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
//  MDMapLoadingMagic.m
//  HaloMD
//
//  Created by null on 11/23/13.
//  Copyright (c) 2013. All rights reserved.
//

#import "MDMapLoadingMagic.h"
#import "mach_override.h"

#define SWAP_IDENTIFIER "magiciswaiting"

static NSMutableArray *executableMaps = nil;
static char *magicSlotBuffer = NULL;
static char *moddedSlotBuffer = NULL;

static void parseMaps(void)
{
	@autoreleasepool
	{
		const int numberOfMaps = 19;
		int mapIndex;
		for (mapIndex = 0; mapIndex < numberOfMaps; mapIndex++)
		{
			// Used hopper to figure this line out
			char *mapName = (char *)(*((int32_t *)(*((int32_t *)0x3691c0) + (mapIndex + mapIndex * 0x2) * 0x4)));
			if (strcmp(mapName, ".map") != 0)
			{
				if (!executableMaps)
				{
					executableMaps = [[NSMutableArray alloc] init];
				}
				[executableMaps addObject:[NSString stringWithUTF8String:mapName]];
			}
			
			if (strcmp(mapName, SWAP_IDENTIFIER) == 0)
			{
				magicSlotBuffer = mapName;
			}
			else if (mapIndex == numberOfMaps-1)
			{
				moddedSlotBuffer = mapName;
			}
		}
	}
}

static int (*oldSvMapFunc)(const char *, const char *);
static int svMapFunc(const char *mapName, const char *mapVariant)
{
	int returnValue = 0;
	
	@autoreleasepool
	{
		NSString *chosenMapName = [NSString stringWithUTF8String:mapName];
		
		if (!magicSlotBuffer)
		{
			parseMaps();
		}
		
		if (magicSlotBuffer)
		{
			// start out innocent
			strcpy(magicSlotBuffer, SWAP_IDENTIFIER);
			
			
			if (strcmp(mapName, SWAP_IDENTIFIER) == 0 || strcmp(mapName, "ui") == 0 || strcmp(mapName, "bitmaps") == 0 || strcmp(mapName, "sounds") == 0)
			{
				chosenMapName = @"bloodgulch";
			}
			else if (![executableMaps containsObject:[NSString stringWithUTF8String:mapName]] && (strlen(mapName) <= 13 || strcmp(mapName, "boardingaction") == 0))
			{
				NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
				NSString *appSupportPath = [libraryPath stringByAppendingPathComponent:@"Application Support"];
				NSString *mapsPath = [[[appSupportPath stringByAppendingPathComponent:@"HaloMD"] stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"Maps"];
				
				if ([[NSFileManager defaultManager] fileExistsAtPath:[mapsPath stringByAppendingPathComponent:[chosenMapName stringByAppendingPathExtension:@"map"]]])
				{
					strcpy(magicSlotBuffer, mapName);
				}
				else
				{
					NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:mapsPath];
					
					int maxBuildNumber = 0;
					NSString *file;
					while (file = [directoryEnumerator nextObject])
					{
						NSString *fullFilePath = [mapsPath stringByAppendingPathComponent:file];
						if (![[fullFilePath stringByDeletingLastPathComponent] isEqualToString:mapsPath])
						{
							// Must be a subdirectory of some kind, skip it..
							continue;
						}
						if (![file hasPrefix:@"."] && [[file pathExtension] isEqualToString:@"map"] && [file hasPrefix:[NSString stringWithFormat:@"%s_", mapName]] && [[file stringByDeletingPathExtension] length] <= 13)
						{
							NSString *fileWithoutExtension = [file stringByDeletingPathExtension];
							NSRange searchRange = [fileWithoutExtension rangeOfString:@"_" options:NSLiteralSearch | NSBackwardsSearch];
							if (searchRange.location != NSNotFound)
							{
								int buildNumber = [[fileWithoutExtension substringFromIndex:searchRange.location + 1] intValue];
								if (buildNumber > maxBuildNumber)
								{
									maxBuildNumber = buildNumber;
									chosenMapName = fileWithoutExtension;
									if (![executableMaps containsObject:chosenMapName])
									{
										strcpy(magicSlotBuffer, [chosenMapName UTF8String]);
									}
								}
							}
						}
					}
				}
			}
		}
		
		returnValue = oldSvMapFunc([chosenMapName UTF8String], mapVariant);
	}
	
	return returnValue;
}

static BOOL didInitializeRand = NO;
static int8_t (*oldLoadMapFunc)(const char *);
static int8_t loadMapFunc(const char *mapName)
{
	if (!magicSlotBuffer)
	{
		parseMaps();
	}
	
	int8_t returnValue = 0;
	
	@autoreleasepool
	{
		NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		NSString *appSupportPath = [libraryPath stringByAppendingPathComponent:@"Application Support"];
		NSString *mapsPath = [[[appSupportPath stringByAppendingPathComponent:@"HaloMD"] stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"Maps"];
		
		NSMutableArray *maps = [[NSMutableArray alloc] initWithObjects:@"bloodgulch", @"crossing", @"barrier", nil];
		if (moddedSlotBuffer && [[NSFileManager defaultManager] fileExistsAtPath:[mapsPath stringByAppendingPathComponent:[[NSString stringWithUTF8String:moddedSlotBuffer] stringByAppendingPathExtension:@"map"]]])
		{
			[maps addObject:[NSString stringWithUTF8String:moddedSlotBuffer]];
		}
		
		if (!didInitializeRand)
		{
			srand(time(NULL));
			didInitializeRand = YES;
		}
		
		const char *newMapName = (strcmp(mapName, SWAP_IDENTIFIER) == 0) ? [[maps objectAtIndex:rand() % [maps count]] UTF8String] : mapName;
		returnValue = oldLoadMapFunc(newMapName);
	}
	
	return returnValue;
}

@implementation MDMapLoadingMagic

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		mach_override_ptr((void *)0x001be2a0, svMapFunc, (void **)&oldSvMapFunc);
		mach_override_ptr((void *)0x0018f320, loadMapFunc, (void **)&oldLoadMapFunc);
	}
	return self;
}

@end
