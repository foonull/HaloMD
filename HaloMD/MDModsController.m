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
//  MDModsController.m
//  HaloMD
//
//  Created by null on 5/26/12.
//

#import "MDModsController.h"
#import "MDModListItem.h"
#import "MDModPatch.h"
#import "MDPluginListItem.h"
#import "MDServer.h"
#import <CommonCrypto/CommonDigest.h>
#import <Growl/Growl.h>
#import "AppDelegate.h"
#import "MDHyperLink.h"
#import "SCEvents.h"
#import "SCEvent.h"
#import "JSONKit.h"

#define MAPS_DIRECTORY [[[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"Maps"]
#define MODS_TEMP_LIST_PATH [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_mods_list.json"]
#define MODS_LIST_PATH [[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"HaloMD_mods_list.json"]
#define MULTIPLAYER_CODES_URL [NSURL URLWithString:@"http://halomd.macgamingmods.com/mods/mods.json.gz"]
#define MOD_DOWNLOAD_URL [NSURL URLWithString:[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/%@.zip", [self currentDownloadingMapIdentifier]]]
#define MOD_DOWNLOAD_FILE [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_download_file.zip"]

#define MOD_PATCH_DOWNLOAD_URL [NSURL URLWithString:[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/%@", [[self currentDownloadingPatch] path]]]
#define MOD_PATCH_DOWNLOAD_FILE [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_download_file.mdpatch"]

#define PLUGINS_DIRECTORY [[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"PlugIns"]
#define PLUGINS_DISABLED_DIRECTORY [[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"PlugIns (Disabled)"]

#define BS_PATCH_PATH @"/usr/bin/bspatch"

@implementation MDModsController

@synthesize modMenuItems;
@synthesize modListDictionary;
@synthesize pluginMenuItems;
@synthesize currentDownloadingMapIdentifier;
@synthesize isInitiated;
@synthesize modDownload;
@synthesize urlToOpen;
@synthesize didDownloadModList;
@synthesize pendingDownload;
@synthesize isWritingUI;
@synthesize currentDownloadingPatch;
@synthesize joiningServer;

static id sharedInstance = nil;
+ (id)modsController
{
	return sharedInstance;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		sharedInstance = self;
	}
	
	return self;
}

- (void)awakeFromNib
{
	[cancelButton setHidden:YES];
}

- (BOOL)validateMenuItem:(NSMenuItem *)theMenuItem
{
	if ([[modsMenu itemArray] containsObject:theMenuItem] && ![appDelegate isInstalled])
	{
		return NO;
	}
	else if ([[pluginsMenu itemArray] containsObject:theMenuItem])
	{
		MDPluginListItem *pluginItem = [theMenuItem representedObject];
		if (pluginItem != nil && [pluginItem isKindOfClass:[MDPluginListItem class]])
		{
			if (pluginItem.enabled)
			{
				[theMenuItem setState:NSOnState];
			}
			else
			{
				[theMenuItem setState:NSOffState];
			}
		}
	}
	else if ([theMenuItem action] == @selector(downloadModList:))
	{
		if (![self canDownloadModList])
		{
			return NO;
		}
	}
	
	return YES;
}

- (int)buildNumberFromMapIdentifier:(NSString *)mapIdentifier
{
	int buildNumber = 0;
	
	NSRange range = [mapIdentifier rangeOfString:@"_" options:NSBackwardsSearch];
	if (range.location != NSNotFound)
	{
		if (range.location+1 < [mapIdentifier length])
		{
			buildNumber = [[mapIdentifier substringFromIndex:range.location+1] intValue];
		}
	}
	
	return buildNumber;
}

- (BOOL)isValidBuildNumber:(NSString *)filename
{
	return ([self buildNumberFromMapIdentifier:filename] > 0);
}

- (BOOL)addModAtPath:(NSString *)filename
{
	NSString *errorString = nil;
	NSString *mapIdentifier = nil;
	
	BOOL success = NO;
	
	if (![self isValidBuildNumber:filename])
	{
		errorString = [NSString stringWithFormat:@"%@ could not be added because its build number is invalid.", [[filename lastPathComponent] stringByDeletingPathExtension]];
		NSLog(@"ERROR: Build number of %@ is invalid", filename);
	}
	else if ([[[filename lastPathComponent] stringByDeletingPathExtension] length] > [MODDED_SLOT_IDENTIFIER length])
	{
		errorString = [NSString stringWithFormat:@"%@ could not be added because its filename is too long.", [[filename lastPathComponent] stringByDeletingPathExtension]];
		NSLog(@"ERROR: File name of %@ is too long", filename);
	}
	else if (![[[filename lastPathComponent] stringByDeletingPathExtension] isEqualToString:[[[filename lastPathComponent] stringByDeletingPathExtension] lowercaseString]])
	{
		errorString = [NSString stringWithFormat:@"%@ could not be added because its filename has a capital letter in it.", [[filename lastPathComponent] stringByDeletingPathExtension]];
		NSLog(@"ERROR: File name of %@ is not all lowercase", filename);
	}
	else
	{
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filename];
		if (fileHandle)
		{
			[fileHandle seekToFileOffset:0x20];
			
			NSData *mapNameData = [fileHandle readDataOfLength:[MODDED_SLOT_IDENTIFIER length]+1];
			mapIdentifier = [[NSString alloc] initWithData:mapNameData encoding:NSUTF8StringEncoding];
			
			// Remove ending zeroes
			[mapIdentifier autorelease];
			mapIdentifier = [NSString stringWithCString:[mapIdentifier UTF8String] encoding:NSUTF8StringEncoding];
			
			if (![mapIdentifier isEqualToString:[[filename lastPathComponent] stringByDeletingPathExtension]])
			{
				errorString = [NSString stringWithFormat:@"%@ could not be added because its internal map name is not matching its filename.", [[filename lastPathComponent] stringByDeletingPathExtension]];
				NSLog(@"ERROR: File %@ does not match its internal map name", filename);
				success = NO;
			}
		}
	}
	
	if (!errorString)
	{
		NSString *destination = [MAPS_DIRECTORY stringByAppendingPathComponent:[filename lastPathComponent]];
		if ([[NSFileManager defaultManager] fileExistsAtPath:destination])
		{
			if (NSRunAlertPanel(@"Mod already exists",
								@"You already have %@. Do you want to replace it?",
								@"Replace", @"Cancel", nil, [filename lastPathComponent]) == NSOKButton)
			{
				[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
															 source:MAPS_DIRECTORY
														destination:@""
															  files:[NSArray arrayWithObject:[destination lastPathComponent]]
																tag:NULL];
			}
		}
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:destination])
		{
			[[NSFileManager defaultManager] moveItemAtPath:filename
													toPath:destination
													 error:nil];
			
			if (mapIdentifier && ![appDelegate isHaloOpen])
			{
				[self writeCurrentModIdentifier:mapIdentifier];
			}
			
			success = YES;
		}
	}
	else
	{
		NSRunAlertPanel(@"Failed Adding Mod",
						errorString,
						@"OK", nil, nil);
	}
	
	return success;
}

- (BOOL)addPluginAtPath:(NSString *)filename
{
	if ([NSBundle bundleWithPath:filename] == nil)
	{
		NSLog(@"%@ is not a valid plugin bundle", filename);
		NSRunAlertPanel(@"Failed Adding Plug-In",
						@"%@ is not a valid Plug-In",
						@"OK", nil, nil, [[filename lastPathComponent] stringByDeletingPathExtension]);
		return NO;
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DIRECTORY])
	{
		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:PLUGINS_DIRECTORY withIntermediateDirectories:NO attributes:nil error:&error])
		{
			NSLog(@"Failed to create PlugIns directory: %@", error);
			return NO;
		}
	}
	
	NSString *newPluginPath = [PLUGINS_DIRECTORY stringByAppendingPathComponent:[filename lastPathComponent]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:newPluginPath])
	{
		[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
													 source:PLUGINS_DIRECTORY
												destination:@""
													  files:[NSArray arrayWithObject:[filename lastPathComponent]]
														tag:0];
	}
	
	NSString *disabledPath = [PLUGINS_DISABLED_DIRECTORY stringByAppendingPathComponent:[filename lastPathComponent]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:disabledPath])
	{
		[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
													 source:PLUGINS_DISABLED_DIRECTORY
												destination:@""
													  files:[NSArray arrayWithObject:[filename lastPathComponent]]
														tag:0];
	}
	
	NSError *error = nil;
	if (![[NSFileManager defaultManager] moveItemAtPath:filename toPath:newPluginPath error:&error])
	{
		NSLog(@"Error moving plugin: %@", error);
		NSRunAlertPanel(@"Failed Adding Plug-In",
						@"%@ could not be moved into PlugIns",
						@"OK", nil, nil, [[filename lastPathComponent] stringByDeletingPathExtension]);
		return NO;
	}
	
	return YES;
}

- (void)openPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton)
	{
		for (NSString *filename in [openPanel filenames])
		{
			[self addModAtPath:filename];
		}
	}
	
	[openPanel release];
}

- (IBAction)addMods:(id)sender
{
	NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
	[openPanel setTitle:@"Add Mods"];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setPrompt:@"Add"];
	
	[openPanel beginForDirectory:nil
							file:nil
						   types:[NSArray arrayWithObject:@"map"]
				modelessDelegate:self
				  didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
					 contextInfo:NULL];
}

- (void)markNotWritingUI
{
	self.isWritingUI = NO;
}

- (void)_writeCurrentUI:(id)unusedObject
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *mapIdentifier = [self readCurrentModIdentifierFromExecutable];
	if ([[NSFileManager defaultManager] fileExistsAtPath:[MAPS_DIRECTORY stringByAppendingPathComponent:[mapIdentifier stringByAppendingPathExtension:@"map"]]])
	{
		NSArray *mapsToModify = [NSArray arrayWithObjects:@"ui.map", @"bloodgulch.map", @"crossing.map", @"barrier.map", nil];
		for (NSString *mapToModify in mapsToModify)
		{
			NSString *mapPath = [[[[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"Maps"] stringByAppendingPathComponent:mapToModify];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:mapPath])
			{
				NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:mapPath];
				
				[fileHandle seekToFileOffset:0x10];
				uint32_t indexOffset = CFSwapInt32LittleToHost(*(uint32_t *)[[fileHandle readDataOfLength:4] bytes]);
				
				[fileHandle seekToFileOffset:indexOffset];
				uint32_t magic = CFSwapInt32LittleToHost(*(uint32_t *)[[fileHandle readDataOfLength:4] bytes]) - indexOffset - 0x28;
				
				[fileHandle seekToFileOffset:indexOffset + 0xC];
				uint32_t numberOfTags = CFSwapInt32LittleToHost(*(uint32_t *)[[fileHandle readDataOfLength:4] bytes]);
				
				uint32_t tagArrayOffset = indexOffset + 0x28;
				
				for (uint32_t tagIndex = 0; tagIndex < numberOfTags; tagIndex++)
				{
					uint32_t currentLocation = 0x20 * tagIndex + tagArrayOffset;
					[fileHandle seekToFileOffset:currentLocation];
					
					NSData *classStringData = [fileHandle readDataOfLength:4];
					
					if ([classStringData length] == 4 && strncmp([classStringData bytes], "rtsu", 4) == 0)
					{
						[fileHandle seekToFileOffset:currentLocation + 0x10];
						uint32_t tagOffset = CFSwapInt32LittleToHost(*(uint32_t *)[[fileHandle readDataOfLength:4] bytes]) - magic;
						
						[fileHandle seekToFileOffset:tagOffset];
						
						const char *mpMapListPath = "ui\\shell\\main_menu\\mp_map_list";
						size_t mpMapListPathLength = strlen(mpMapListPath)+1;
						NSData *tagPathData = [fileHandle readDataOfLength:mpMapListPathLength];
						
						if ([tagPathData length] == mpMapListPathLength && strncmp([tagPathData bytes], mpMapListPath, mpMapListPathLength) == 0)
						{
							[fileHandle seekToFileOffset:currentLocation + 0x14];
							uint32_t namesOffset = CFSwapInt32LittleToHost(*(uint32_t *)[[fileHandle readDataOfLength:4] bytes]) - magic + 0x1B0;
							uint32_t gephyOffset = namesOffset + 0x1A0;
							
							[fileHandle seekToFileOffset:gephyOffset];
							unichar buffer[13];
							memset(buffer, 0, sizeof(buffer));
							
							NSString *mapNameUI = mapIdentifier;
							MDModListItem *listItem = [modListDictionary objectForKey:mapIdentifier];
							if (listItem)
							{
								mapNameUI = [listItem name];
							}
							
							[mapNameUI getCharacters:buffer range:NSMakeRange(0, MIN([mapNameUI length], sizeof(buffer) / sizeof(unichar)))];
							[fileHandle writeData:[NSData dataWithBytes:buffer length:sizeof(buffer)]];
						}
					}
				}
				
				[fileHandle closeFile];
			}
		}
	}
	
	[self performSelectorOnMainThread:@selector(markNotWritingUI) withObject:nil waitUntilDone:NO];
	
	[autoreleasePool release];
}

- (void)writeCurrentUI
{
	if (self.isWritingUI)
	{
		// Try again later
		[self performSelector:@selector(writeCurrentUI) withObject:nil afterDelay:0.01];
	}
	else
	{
		[NSThread detachNewThreadSelector:@selector(_writeCurrentUI:) toTarget:self withObject:nil];
	}
}

- (BOOL)writeCurrentModIdentifier:(NSString *)mapIdentifier
{
	BOOL success = NO;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[MAPS_DIRECTORY stringByAppendingPathComponent:[mapIdentifier stringByAppendingPathExtension:@"map"]]])
	{
		NSString *haloExecutablePath = [[[[[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"HaloMD.app"] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:@"Halo"];
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:haloExecutablePath];
		
		if (fileHandle)
		{
			char buffer[[MODDED_SLOT_IDENTIFIER length]+1];
			memset(buffer, 0, sizeof(buffer));
			
			strncpy(buffer, [mapIdentifier UTF8String], sizeof(buffer)-1);
			
			[fileHandle seekToFileOffset:0x3BCEEC];
			[fileHandle writeData:[NSData dataWithBytes:buffer length:sizeof(buffer)]];
			
			[fileHandle seekToFileOffset:0x76B3B0];
			[fileHandle writeData:[NSData dataWithBytes:buffer length:sizeof(buffer)]];
			
			[self writeCurrentUI];
			
			[fileHandle closeFile];
			
			success = YES;
		}
	}
	
	return success;
}

- (void)enableModWithMapIdentifier:(NSString *)mapIdentifier
{
	for (NSMenuItem *item in [self modMenuItems])
	{
		if ([[[item representedObject] identifier] isEqualToString:mapIdentifier])
		{
			[self enableMod:item];
			break;
		}
	}
}

- (void)enableMod:(NSMenuItem *)menuItem
{
	if ([menuItem state] == NSOnState)
	{
		return;
	}
	
	if ([appDelegate isHaloOpen])
	{
		if (NSRunAlertPanel(@"Halo is Running",
						    @"You have to quit Halo in order to enable this mod.",
						    @"Quit", @"Cancel", nil) == NSOKButton)
		{
			[appDelegate terminateHaloInstances];
		}
		else
		{
			return;
		}
	}
	
	if ([self writeCurrentModIdentifier:[[menuItem representedObject] identifier]])
	{
		[menuItem setState:NSOnState];
		
		for (NSMenuItem *item in [self modMenuItems])
		{
			if (item != menuItem)
			{
				[item setState:NSOffState];
			}
		}
	}
}

- (NSArray *)mapsToIgnore
{
	return [[[NSArray alloc] initWithObjects:@"bloodgulch", @"beavercreek", @"bitmaps", @"boardingaction", @"carousel", @"chillout", @"damnation", @"dangercanyon", @"deathisland", @"hangemhigh", @"icefields", @"infinity", @"longest", @"prisoner", @"putput", @"ratrace", @"sidewinder", @"sounds", @"timberland", @"ui", @"wizard", @"a10", @"a30", @"a50", @"b30", @"b40", @"c10", @"c20", @"c40", @"d20", @"d40", nil] autorelease];
}

- (NSString *)readCurrentModIdentifierFromExecutable
{
	NSString *modIdentifier = nil;
	
	NSString *haloExecutablePath = [[[[[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"HaloMD.app"] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:@"Halo"];
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:haloExecutablePath];
	if (fileHandle)
	{
		[fileHandle seekToFileOffset:0x3BCEEC];
		NSData *identifierData = [fileHandle readDataOfLength:[MODDED_SLOT_IDENTIFIER length]+1];
		modIdentifier = [[[NSString alloc] initWithData:identifierData encoding:NSUTF8StringEncoding] autorelease];
		// Remove ending zeroes
		modIdentifier = [NSString stringWithCString:[modIdentifier UTF8String] encoding:NSUTF8StringEncoding];
	}
	
	return modIdentifier;
}

- (void)makeModMenuItems
{
	NSString *initialModIdentifier = nil;
	
	if (!modMenuItems)
	{
		[self setModMenuItems:[NSMutableArray array]];
	}
	else
	{
		for (id menuItem in modMenuItems)
		{
			[modsMenu removeItem:menuItem];
		}
		
		[[self modMenuItems] removeAllObjects];
		
		if ([[[modsMenu itemArray] lastObject] action] == @selector(doNothing:))
		{
			[modsMenu removeItem:[[modsMenu itemArray] lastObject]];
		}
	}
	
	initialModIdentifier = [self readCurrentModIdentifierFromExecutable];
	
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:MAPS_DIRECTORY];
	NSString *file = nil;
	
	[directoryEnumerator skipDescendents];
	
	while (file = [directoryEnumerator nextObject])
	{
		if ([[file pathExtension] isEqualToString:@"map"] && ![[self mapsToIgnore] containsObject:[file stringByDeletingPathExtension]])
		{
			MDModListItem *listItem = [[MDModListItem alloc] init];
			[listItem setIdentifier:[file stringByDeletingPathExtension]];
			
			[listItem setName:[listItem identifier]];
			BOOL validBuildNumber = [self isValidBuildNumber:[listItem identifier]];
			
			if (validBuildNumber)
			{
				NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[MAPS_DIRECTORY stringByAppendingPathComponent:file]];
				if (fileHandle)
				{
					[fileHandle seekToFileOffset:0x20];
					
					NSData *mapNameData = [fileHandle readDataOfLength:[MODDED_SLOT_IDENTIFIER length]+1];
					NSString *mapIdentifier = [[NSString alloc] initWithData:mapNameData encoding:NSUTF8StringEncoding];
					
					// Remove ending zeroes
					[mapIdentifier autorelease];
					mapIdentifier = [NSString stringWithCString:[mapIdentifier UTF8String] encoding:NSUTF8StringEncoding];
					
					if ([mapIdentifier isEqualToString:[listItem identifier]])
					{
						NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[listItem name] ? [listItem name] : @"" action:@selector(enableMod:) keyEquivalent:@""];
						[menuItem setTarget:self];
						[menuItem setRepresentedObject:listItem];
						
						if (initialModIdentifier && [mapIdentifier isEqualToString:initialModIdentifier])
						{
							[menuItem setState:NSOnState];
							initialModIdentifier = nil;
						}
						
						[[self modMenuItems] addObject:menuItem];
						[modsMenu addItem:menuItem];
						
						[menuItem release];
					}
				}
			}
			
			[listItem release];
		}
	}
	
	if ([[self modMenuItems] count] == 0)
	{
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"No Available Mods" action:@selector(doNothing:) keyEquivalent:@""];
		[menuItem setEnabled:NO];
		[modsMenu addItem:menuItem];
		[menuItem release];
	}
	else if (initialModIdentifier && ![appDelegate isHaloOpen]) // A mod isn't swapped in, let's swap one in
	{
		if ([[self modMenuItems] count] > 0)
		{
			[self enableMod:[[self modMenuItems] objectAtIndex:0]];
		}
	}
}

- (void)enablePlugin:(NSMenuItem *)menuItem
{
	MDPluginListItem *pluginItem = [menuItem representedObject];
	NSString *normalPath = [PLUGINS_DIRECTORY stringByAppendingPathComponent:pluginItem.filename];
	NSString *disabledPath = [PLUGINS_DISABLED_DIRECTORY stringByAppendingPathComponent:pluginItem.filename];
	
	if (pluginItem.enabled)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DISABLED_DIRECTORY] && ![[NSFileManager defaultManager] fileExistsAtPath:disabledPath])
		{
			if ([[NSFileManager defaultManager] moveItemAtPath:normalPath toPath:disabledPath error:NULL])
			{
				pluginItem.enabled = NO;
			}
		}
	}
	else
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DIRECTORY] && ![[NSFileManager defaultManager] fileExistsAtPath:normalPath])
		{
			if ([[NSFileManager defaultManager] moveItemAtPath:disabledPath toPath:normalPath error:NULL])
			{
				pluginItem.enabled = YES;
			}
		}
	}
}

- (void)addPluginsFromDirectory:(NSString *)directory intoArray:(NSMutableArray *)pluginItems enabled:(BOOL)enabled
{
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:directory];
	
	for (NSString *file in directoryEnumerator)
	{
		if ([[file pathExtension] isEqualToString:@"mdplugin"])
		{
			NSBundle *pluginBundle = [NSBundle bundleWithPath:[directory stringByAppendingPathComponent:file]];
			if (pluginBundle != nil)
			{
				NSNumber *globalPluginValue = [[pluginBundle infoDictionary] objectForKey:@"MDGlobalPlugin"];
				if (globalPluginValue != nil && [globalPluginValue boolValue])
				{
					MDPluginListItem *pluginItem = [[MDPluginListItem alloc] init];
					
					pluginItem.enabled = enabled;
					pluginItem.filename = file;
					
					[pluginItems addObject:pluginItem];
					
					[pluginItem release];
				}
			}
		}
		
		[directoryEnumerator skipDescendents];
	}
}

- (void)makePluginMenuItems
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DIRECTORY])
	{
		if (![[NSFileManager defaultManager] createDirectoryAtPath:PLUGINS_DIRECTORY withIntermediateDirectories:NO attributes:nil error:NULL])
		{
			NSLog(@"Failed to create %@", PLUGINS_DIRECTORY);
			return;
		}
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DISABLED_DIRECTORY])
	{
		if (![[NSFileManager defaultManager] createDirectoryAtPath:PLUGINS_DISABLED_DIRECTORY withIntermediateDirectories:NO attributes:nil error:NULL])
		{
			NSLog(@"Failed to create %@", PLUGINS_DISABLED_DIRECTORY);
			return;
		}
	}
	
	if ([self pluginMenuItems] == nil)
	{
		[self setPluginMenuItems:[NSMutableArray array]];
	}
	else
	{
		for (id menuItem in [self pluginMenuItems])
		{
			[pluginsMenu removeItem:menuItem];
		}
		
		[[self pluginMenuItems] removeAllObjects];
		
		if ([[[pluginsMenu itemArray] lastObject] action] == @selector(doNothing:))
		{
			[pluginsMenu removeItem:[[pluginsMenu itemArray] lastObject]];
		}
	}
	
	NSMutableArray *newPluginItems = [NSMutableArray array];
	[self addPluginsFromDirectory:PLUGINS_DIRECTORY intoArray:newPluginItems enabled:YES];
	[self addPluginsFromDirectory:PLUGINS_DISABLED_DIRECTORY intoArray:newPluginItems enabled:NO];
	
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"filename" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
	NSArray *sortedItems = [newPluginItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	if (sortedItems.count > 0)
	{
		for (MDPluginListItem *pluginItem in newPluginItems)
		{
			NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:[pluginItem.filename stringByDeletingPathExtension] action:@selector(enablePlugin:) keyEquivalent:@""];
			newMenuItem.representedObject = pluginItem;
			newMenuItem.target = self;
			
			[pluginsMenu addItem:newMenuItem];
			[[self pluginMenuItems] addObject:newMenuItem];
			[newMenuItem release];
		}
	}
	else
	{
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"No Available Plug-Ins" action:@selector(doNothing:) keyEquivalent:@""];
		[menuItem setEnabled:NO];
		[pluginsMenu addItem:menuItem];
		[menuItem release];
	}
}

- (void)installOnlineModWithIdentifier:(NSString *)identifier
{
	if (![self currentDownloadingMapIdentifier])
	{
		[self downloadMod:identifier];
	}
	else
	{
		NSRunAlertPanel(@"Installation in Progress",
						@"You are currently installing %@. Please try again when the installation finishes.",
						@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
		
	}
}

- (void)installOnlineMod:(id)sender
{
	[self installOnlineModWithIdentifier:[[sender representedObject] identifier]];
}

- (void)updateModMenuTitles
{
	NSMutableArray *itemsToRemove = [NSMutableArray array];
	
	for (NSMenuItem *modMenuItem in modMenuItems)
	{
		MDModListItem *item = [[self modListDictionary] objectForKey:[[modMenuItem representedObject] identifier]];
		if (item)
		{
			BOOL shouldAddMenuItem = YES;
			
			for (NSMenuItem *previousMenuItem in modMenuItems)
			{
				if (previousMenuItem == modMenuItem)
				{
					break;
				}
				
				if (![itemsToRemove containsObject:previousMenuItem] && [[[previousMenuItem representedObject] name] isEqualToString:[item name]])
				{
					int previousBuildNumber =  [self buildNumberFromMapIdentifier:[[previousMenuItem representedObject] identifier]];
					int currentBuildNumber = [self buildNumberFromMapIdentifier:[item identifier]];
					
					if (currentBuildNumber > previousBuildNumber)
					{
						[itemsToRemove addObject:previousMenuItem];
					}
					else if (currentBuildNumber < previousBuildNumber)
					{
						shouldAddMenuItem = NO;
					}
				}
			}
			
			if (shouldAddMenuItem)
			{
				[modMenuItem setRepresentedObject:item];
				if ([item name])
				{
					[modMenuItem setTitle:[item name]];
				}
				if ([item description])
				{
					[modMenuItem setToolTip:[item description]];
				}
			}
		}
	}
	
	for (id modMenuItem in itemsToRemove)
	{
		// This should never fail but just to be safe, removing something not in the menu could raise an exception
		if ([[modsMenu itemArray] containsObject:modMenuItem])
		{
			[modsMenu removeItem:modMenuItem];
		}
		[[self modMenuItems] removeObject:modMenuItem];
	}
	
	// Sort the mods based on title
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
	NSArray *sortedMenuItems = [[self modMenuItems] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	for (id modItem in [self modMenuItems])
	{
		[modsMenu removeItem:modItem];
	}
	
	[self setModMenuItems:[NSMutableArray arrayWithArray:sortedMenuItems]];
	
	for (id modItem in [self modMenuItems])
	{
		[modsMenu addItem:modItem];
	}
	
	[appDelegate updateHiddenServers];
}

- (void)removeAllItemsFromMenu:(NSMenu *)menu
{
	if ([menu respondsToSelector:@selector(removeAllItems)])
	{
		[menu removeAllItems];
	}
	else
	{
		while ([[menu itemArray] count] > 0)
		{
			[menu removeItemAtIndex:0];
		}
	}
}

- (void)makeModsList
{
	NSDictionary *modsDictionary = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:MODS_LIST_PATH])
	{
		NSData *jsonData = [NSData dataWithContentsOfFile:MODS_LIST_PATH];
		if (jsonData != nil)
		{
			id jsonSerializationClass = NSClassFromString(@"NSJSONSerialization");
			if (jsonSerializationClass != nil)
			{
				NSError *error = nil;
				modsDictionary = [jsonSerializationClass JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
				if (!modsDictionary)
				{
					NSLog(@"Error: could not read JSON dictionary");
					NSLog(@"%@", error);
				}
			}
			else
			{
				modsDictionary = [[JSONDecoder decoder] objectWithData:jsonData];
			}
		}
	}
	
	if (modsDictionary != nil)
	{
		// Remove blank separator and refresh list options..
		NSMutableArray *onlineItemsToRemove = [NSMutableArray array];
		for (id item in [onlineModsMenu itemArray])
		{
			if (![item representedObject])
			{
				[onlineItemsToRemove addObject:item];
			}
		}
		
		for (id item in onlineItemsToRemove)
		{
			[onlineModsMenu removeItem:item];
		}
		
		[self setModListDictionary:[NSMutableDictionary dictionary]];
		
		for (NSDictionary *modDictionary in [modsDictionary objectForKey:@"Mods"])
		{
			MDModListItem *listItem = [[MDModListItem alloc] init];
			
			[listItem setIdentifier:[modDictionary objectForKey:@"identifier"]];
			[listItem setVersion:[modDictionary objectForKey:@"human_version"]];
			[listItem setName:[modDictionary objectForKey:@"name"]];
			[listItem setDescription:[modDictionary objectForKey:@"description"]];
			[listItem setMd5Hash:[modDictionary objectForKey:@"hash"]];
			
			NSMutableArray *patches = [NSMutableArray array];
			for (NSDictionary *patchDictionary in [modDictionary objectForKey:@"patches"])
			{
				MDModPatch *newPatch = [[MDModPatch alloc] init];
				[newPatch setBaseIdentifier:[patchDictionary objectForKey:@"base_identifier"]];
				[newPatch setBaseHash:[patchDictionary objectForKey:@"base_hash"]];
				[newPatch setPath:[patchDictionary objectForKey:@"path"]];
				[patches addObject:newPatch];
				[newPatch release];
			}
			
			[listItem setPatches:patches];
			
			if ([listItem name])
			{
				NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[listItem name] action:@selector(installOnlineMod:) keyEquivalent:@""];
				[menuItem setTarget:self];
				[menuItem setRepresentedObject:listItem];
				[menuItem setToolTip:[listItem description]];
				
				NSMenuItem *previousItem = [onlineModsMenu itemWithTitle:[listItem name]];
				if (previousItem)
				{
					int previousBuildNumber = [self buildNumberFromMapIdentifier:[[previousItem representedObject] identifier]];
					int currentBuildNumber = [self buildNumberFromMapIdentifier:[[menuItem representedObject] identifier]];
					
					if (currentBuildNumber > previousBuildNumber)
					{
						[onlineModsMenu removeItem:previousItem];
						[onlineModsMenu addItem:menuItem];
					}
				}
				else
				{
					[onlineModsMenu addItem:menuItem];
				}
				
				[[self modListDictionary] setObject:listItem forKey:[listItem identifier]];
				
				[menuItem release];
			}
			
			[listItem release];
		}
		
		// Sort the online menu items
		NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
		NSArray *sortedMenuItems = [[onlineModsMenu itemArray] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		
		[self removeAllItemsFromMenu:onlineModsMenu];
		for (id item in sortedMenuItems)
		{
			[onlineModsMenu addItem:item];
		}
		
		// Add refresh list and blank separator options
		NSMenuItem *refreshDownloadListMenuItem = [[NSMenuItem alloc] initWithTitle:@"Refresh List" action:@selector(downloadModList:) keyEquivalent:@"r"];
		[refreshDownloadListMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
		[refreshDownloadListMenuItem setTarget:self];
		[onlineModsMenu addItem:[NSMenuItem separatorItem]];
		[onlineModsMenu addItem:refreshDownloadListMenuItem];
		[refreshDownloadListMenuItem release];
		
		[self updateModMenuTitles];
		
		[appDelegate updateHiddenServers];
		
		[self writeCurrentUI];
	}
}

- (void)showUpdateNoticeIfNeeded
{
	if ([appDelegate isQueryingServers] || [self currentDownloadingMapIdentifier])
	{
		[self performSelector:@selector(showUpdateNoticeIfNeeded) withObject:nil afterDelay:10.0];
		return;
	}
	
	NSMutableArray *itemsToUpdate = [NSMutableArray array];
	
	for (NSMenuItem *modMenuItem in modMenuItems)
	{
		MDModListItem *modItem = [modMenuItem representedObject];
		
		BOOL isLatestVersionInstalled = YES;
		for (NSMenuItem *innerMenuItem in modMenuItems)
		{
			MDModListItem *innerModItem = [innerMenuItem representedObject];
			
			if (innerMenuItem != modMenuItem && [[modItem name] isEqualToString:[innerModItem name]] && [self buildNumberFromMapIdentifier:[modItem identifier]] < [self buildNumberFromMapIdentifier:[innerModItem identifier]])
			{
				isLatestVersionInstalled = NO;
				break;
			}
		}
		
		if (isLatestVersionInstalled)
		{
			MDModListItem *onlineItem = nil;
			for (NSMenuItem *onlineMenuItem in [onlineModsMenu itemArray])
			{
				MDModListItem *onlineModItem = [onlineMenuItem representedObject];
				if (onlineModItem && [[onlineModItem name] isEqualToString:[modItem name]])
				{
					onlineItem = onlineModItem;
					break;
				}
			}
			
			if ([self buildNumberFromMapIdentifier:[onlineItem identifier]] > [self buildNumberFromMapIdentifier:[modItem identifier]])
			{
				[itemsToUpdate addObject:onlineItem];
			}
		}
	}
	
	if ([itemsToUpdate count] > 0)
	{
		MDModListItem *randomItem = [itemsToUpdate objectAtIndex:rand() % [itemsToUpdate count]];
		
		NSAttributedString *statusString =  [NSAttributedString MDHyperlinkFromString:[NSString stringWithFormat:@"Update %@", [randomItem name]] withURL:[NSURL URLWithString:[NSString stringWithFormat:@"halomdinstall://%@", [randomItem identifier]]]];
		
		[appDelegate setStatus:statusString];
	}
}

- (void)stopAndStartDownloadModListTimer
{
	// Check download list every 30 minutes
	[downloadModListTimer invalidate];
	[downloadModListTimer release];
	downloadModListTimer = [[NSTimer scheduledTimerWithTimeInterval:60*30 target:self selector:@selector(downloadModList) userInfo:nil repeats:YES] retain];
}

- (IBAction)downloadModList:(id)sender
{
	[self downloadModList];
}

- (BOOL)canDownloadModList
{
	return (!isDownloadingModList && ![appDelegate isHaloOpen]);
}

- (void)downloadModList
{
	if ([self canDownloadModList])
	{
		NSURLRequest *request = [NSURLRequest requestWithURL:MULTIPLAYER_CODES_URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
		NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
		
		[download setDestination:MODS_TEMP_LIST_PATH allowOverwrite:YES];
		isDownloadingModList = YES;
		
		[self stopAndStartDownloadModListTimer];
	}
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	if ([[[download request] URL] isEqual:MULTIPLAYER_CODES_URL])
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:MODS_LIST_PATH])
		{
			[[NSFileManager defaultManager] removeItemAtPath:MODS_LIST_PATH error:nil];
		}
		
		[[NSFileManager defaultManager] moveItemAtPath:MODS_TEMP_LIST_PATH
												toPath:MODS_LIST_PATH
												 error:nil];
		
		[self makeModsList];
		[self setDidDownloadModList:YES];
		isDownloadingModList = NO;
		if ([self pendingDownload])
		{
			NSLog(@"Re-trying to download %@", [self pendingDownload]);
			[self downloadMod:[self pendingDownload]];
			[self setPendingDownload:nil];
		}
		[self performSelector:@selector(showUpdateNoticeIfNeeded) withObject:nil afterDelay:10.0];
	}
	else if ([[[[download request] URL] absoluteString] rangeOfString:@".zip"].location != NSNotFound)
	{
		NSString *unzipDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_Unzip"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:unzipDirectory])
		{
			[[NSFileManager defaultManager] removeItemAtPath:unzipDirectory error:nil];
		}
		
		if ([[NSFileManager defaultManager] createDirectoryAtPath:unzipDirectory withIntermediateDirectories:NO attributes:nil error:nil])
		{
			NSTask *unzipTask = [[NSTask alloc] init];
			
			[unzipTask setLaunchPath:@"/usr/bin/unzip"];
			[unzipTask setArguments:[NSArray arrayWithObjects:@"-o", @"-q", @"-d", unzipDirectory, MOD_DOWNLOAD_FILE, nil]];
			
			BOOL didUnzip = YES;
			
			@try
			{
				[unzipTask launch];
				[unzipTask waitUntilExit];
			}
			@catch (NSException *exception)
			{
				NSLog(@"Failed unzipping: %@, %@", [exception name], [exception reason]);
				didUnzip = NO;
			}
			
			[unzipTask release];
			
			if (didUnzip)
			{
				NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:unzipDirectory];
				NSString *file = nil;
				while (file = [directoryEnumerator nextObject])
				{
					if ([[file pathExtension] isEqualToString:@"map"] && ![[self mapsToIgnore] containsObject:[[file lastPathComponent] stringByDeletingPathExtension]] && ![[file lastPathComponent] hasPrefix:@"."])
					{
						if (![[appDelegate window] isKeyWindow] || ![NSApp isActive])
						{
							[NSClassFromString(@"GrowlApplicationBridge")
							 notifyWithTitle:@"Download Finished"
							 description:[NSString stringWithFormat:@"You can now play %@", [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]]
							 notificationName:@"ModDownloaded"
							 iconData:nil
							 priority:0
							 isSticky:NO
							 clickContext:@"ModDownloaded"];
						}
						
						if ([self addModAtPath:[unzipDirectory stringByAppendingPathComponent:file]] && [[appDelegate window] isKeyWindow] && [NSApp isActive] && [self joiningServer])
						{
							[appDelegate joinServer:[self joiningServer]	];
						}
					}
				}
			}
			else
			{
				NSRunAlertPanel(@"Mod Installation Failed",
								@"%@ failed to install. Perhaps the downloaded file was corrupted.",
								@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
			}
			
			[[NSFileManager defaultManager] removeItemAtPath:unzipDirectory error:nil];
		}
		else
		{
			NSRunAlertPanel(@"Mod Installation Failed",
							@"%@ failed to install. HaloMD could not create a temporary directory for installation.",
							@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
		}
		
		[self setJoiningServer:nil];
		
		[appDelegate setStatus:nil];
		[cancelButton setHidden:YES];
		[refreshButton setHidden:NO];
		
		[self setModDownload:nil];
		
		[self setCurrentDownloadingMapIdentifier:nil];
	}
	else if ([[[[download request] URL] absoluteString] rangeOfString:@".mdpatch"].location != NSNotFound)
	{
		NSString *baseMapPath = [self originalMapPathFromIdentifier:[[self currentDownloadingPatch] baseIdentifier]];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:baseMapPath])
		{
			NSLog(@"ERROR: Failed to find base map: %@", baseMapPath);
			NSRunAlertPanel(@"Mod Installation Failed",
							@"%@ failed to install because %@ could not be found.",
							@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name], [[self currentDownloadingPatch] baseIdentifier]);
		}
		else
		{
			NSString *newMapPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[self currentDownloadingMapIdentifier] stringByAppendingPathExtension:@"map"]];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:newMapPath])
			{
				[[NSFileManager defaultManager] removeItemAtPath:newMapPath error:nil];
			}
			
			NSTask *patchTask = [[NSTask alloc] init];
			
			[patchTask setLaunchPath:BS_PATCH_PATH];
			[patchTask setArguments:[NSArray arrayWithObjects:baseMapPath, newMapPath, MOD_PATCH_DOWNLOAD_FILE, nil]];
			
			BOOL didPatch = YES;
			
			@try
			{
				[patchTask launch];
				[patchTask waitUntilExit];
			}
			@catch (NSException *exception)
			{
				NSLog(@"Failed patching: %@, %@", [exception name], [exception reason]);
				didPatch = NO;
			}
			
			[patchTask release];
			
			NSString *mapHash = [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] md5Hash];
			if (mapHash && ![mapHash isEqualToString:[self md5HashFromFilePath:newMapPath]])
			{
				NSLog(@"Map hash %@ does not match with downloaded file", mapHash);
				didPatch = NO;
			}
			
			if (didPatch)
			{
				if (![[appDelegate window] isKeyWindow] || ![NSApp isActive])
				{
					[NSClassFromString(@"GrowlApplicationBridge")
					 notifyWithTitle:@"Download Finished"
					 description:[NSString stringWithFormat:@"You can now play %@", [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]]
					 notificationName:@"ModDownloaded"
					 iconData:nil
					 priority:0
					 isSticky:NO
					 clickContext:@"ModDownloaded"];
				}
				
				if ([self addModAtPath:newMapPath] && [[appDelegate window] isKeyWindow] && [NSApp isActive] && [self joiningServer])
				{
					[appDelegate joinServer:[self joiningServer]];
				}
			}
			else
			{
				NSRunAlertPanel(@"Mod Installation Failed",
								@"%@ failed to install. Perhaps the downloaded patch file was corrupted.",
								@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
			}
			
			[[NSFileManager defaultManager] removeItemAtPath:MOD_PATCH_DOWNLOAD_FILE error:nil];
		}
		
		[self setJoiningServer:nil];
		
		[appDelegate setStatus:nil];
		[cancelButton setHidden:YES];
		[refreshButton setHidden:NO];
		
		[self setModDownload:nil];
		
		[self setCurrentDownloadingPatch:nil];
		[self setCurrentDownloadingMapIdentifier:nil];
	}
	
	[download release];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	if ([[[[download request] URL] absoluteString] rangeOfString:@".zip"].location != NSNotFound || [[[[download request] URL] absoluteString] rangeOfString:@".mdpatch"].location != NSNotFound)
	{
		// Ensure currentContentLength won't exceed expectedContentLength
		if (currentContentLength < expectedContentLength)
		{
			currentContentLength += length;
			if (currentContentLength > expectedContentLength)
			{
				currentContentLength = expectedContentLength;
			}
			[appDelegate setStatusWithoutWait:[NSString stringWithFormat:@"Installing %@... (%d%%)", [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name], (int)((100.0 * currentContentLength) / expectedContentLength)]];
		}
	}
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	if ([[[[download request] URL] absoluteString] rangeOfString:@".zip"].location != NSNotFound || [[[[download request] URL] absoluteString] rangeOfString:@".mdpatch"].location != NSNotFound)
	{
		expectedContentLength = [response expectedContentLength];
		currentContentLength = 0;
		
		[cancelButton setHidden:NO];
		[refreshButton setHidden:YES];
	}
}

- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)response fromByte:(long long)startingByte
{
	currentContentLength = startingByte;
	expectedContentLength = [response expectedContentLength];
	
	[resumeTimeoutDate release];
	resumeTimeoutDate = nil;
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	NSLog(@"Failed to download file: %@, %@", [[download request] URL], [error localizedDescription]);
	
	[self setJoiningServer:nil];
	
	if ([[[[download request] URL] absoluteString] rangeOfString:@".zip"].location != NSNotFound || [[[[download request] URL] absoluteString] rangeOfString:@".mdpatch"].location != NSNotFound)
	{
		NSString *destination = [self currentDownloadingPatch] ? MOD_PATCH_DOWNLOAD_FILE : MOD_DOWNLOAD_FILE;
		
		if (!resumeTimeoutDate)
		{
			resumeTimeoutDate = [[NSDate date] retain];
		}
		
		if ([[NSDate date] timeIntervalSinceDate:resumeTimeoutDate] <= 7.0 && [download resumeData])
		{
			NSURLDownload *newDownload = [[NSURLDownload alloc] initWithResumeData:[download resumeData] delegate:self path:destination];
			[newDownload setDeletesFileUponFailure:NO];
			[self setModDownload:newDownload];
		}
		else
		{
			NSRunAlertPanel(@"Mod Download Failed",
							@"%@ failed to finish downloading.",
							@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
			
			[self setCurrentDownloadingMapIdentifier:nil];
			[self setCurrentDownloadingPatch:nil];
			
			[appDelegate setStatus:nil];
			
			[cancelButton setHidden:YES];
			[refreshButton setHidden:NO];
			[self setModDownload:nil];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:destination])
			{
				[[NSFileManager defaultManager] removeItemAtPath:destination error:NULL];
			}
		}
	}
	else if ([[[download request] URL] isEqual:MULTIPLAYER_CODES_URL])
	{
		isDownloadingModList = NO;
		[self setPendingDownload:nil];
	}
	
	[download release];
}

- (NSString *)originalMapPathFromIdentifier:(NSString *)identifier
{
	NSString *identifierWithPathExtension = [identifier stringByAppendingPathExtension:@"map"];
	return [[NSArray arrayWithObjects:@"bloodgulch", @"crossing", @"barrier", nil] containsObject:identifier] ? [[[appDelegate resourceGameDataPath] stringByAppendingPathComponent:@"Maps"] stringByAppendingPathComponent:identifierWithPathExtension] : [MAPS_DIRECTORY stringByAppendingPathComponent:identifierWithPathExtension];
}

- (NSString *)md5HashFromFilePath:(NSString *)filePath
{
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	unsigned char *result = calloc(CC_MD5_DIGEST_LENGTH, 1);
	CC_MD5([data bytes], (unsigned int)[data length], result);
	
	NSMutableString *hash = [NSMutableString string];
	for (int hashIndex = 0; hashIndex < CC_MD5_DIGEST_LENGTH; hashIndex++)
	{
		[hash appendFormat:@"%02x", result[hashIndex]];
	}
	free(result);
	
	return [[hash copy] autorelease];
}

- (void)downloadMod:(NSString *)mapIdentifier
{
	if (![self isValidBuildNumber:mapIdentifier])
	{
		NSLog(@"Invalid build number from identifier: %@", mapIdentifier);
		return;
	}
	
	NSString *modName =  [[modListDictionary objectForKey:mapIdentifier] name];
	if (!modName)
	{
		NSLog(@"Could not find map identifier %@", mapIdentifier);
		if (![self didDownloadModList])
		{
			NSLog(@"Trying to re-download mod list...");
			[self setPendingDownload:mapIdentifier];
			[self downloadModList];
		}
		return;
	}
	
	[self setCurrentDownloadingMapIdentifier:mapIdentifier];
	
	[appDelegate setStatus:[NSString stringWithFormat:@"Installing %@...", modName]];
	
	// Find out if we can download a patched version
	MDModPatch *foundPatch = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:BS_PATCH_PATH])
	{
		for (MDModPatch *patch in [[modListDictionary objectForKey:mapIdentifier] patches])
		{
			NSString *mapPath = [self originalMapPathFromIdentifier:[patch baseIdentifier]];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:mapPath])
			{
				if ([[self md5HashFromFilePath:mapPath] isEqualToString:[patch baseHash]])
				{
					foundPatch = patch;
					break;
				}
			}
		}
	}
	
	[self setCurrentDownloadingPatch:foundPatch];
	
	[resumeTimeoutDate release];
	resumeTimeoutDate = nil;
	
	NSURL *downloadURL = [self currentDownloadingPatch] ? MOD_PATCH_DOWNLOAD_URL : MOD_DOWNLOAD_URL;
	NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	
	NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
	
	NSString *destination = [self currentDownloadingPatch] ? MOD_PATCH_DOWNLOAD_FILE : MOD_DOWNLOAD_FILE;
	[download setDestination:destination allowOverwrite:YES];
	[download setDeletesFileUponFailure:NO];
	[self setModDownload:download];
}

- (void)requestModDownload:(NSString *)mapIdentifier andJoinServer:(MDServer *)server
{
	MDModListItem *listItem = [modListDictionary objectForKey:mapIdentifier];
	
	if ([self currentDownloadingMapIdentifier])
	{
		NSRunAlertPanel(@"Modded Game",
						@"In order to join this game, you will have to install %@. However, you are currently installing %@. Please try again when the installation finishes.",
						@"OK", nil, nil, [listItem name], [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
	}
	else
	{
		NSString *modName = [[modListDictionary objectForKey:mapIdentifier] name];
		
		NSMenuItem *menuItem = nil;
		for (id item in [self modMenuItems])
		{
			if ([[[item representedObject] name] isEqualToString:modName] && (!menuItem || [self buildNumberFromMapIdentifier:[[menuItem representedObject] identifier]] > [self buildNumberFromMapIdentifier:[[item representedObject] identifier]]))
			{
				menuItem = item;
			}
		}
		
		if (menuItem)
		{
			MDModListItem *currentListItem = [modListDictionary objectForKey:[[menuItem representedObject] identifier]];
			int currentBuildNumber = [self buildNumberFromMapIdentifier:[currentListItem identifier]];
			int desiredBuildNumber = [self buildNumberFromMapIdentifier:mapIdentifier];
			
			if (NSRunAlertPanel(@"Modded Game",
								@"Do you want to install %@ (v%@) in order to join this game? You currently have %@ version (v%@) installed.",
								@"Install", @"Cancel", nil, [listItem name],  [listItem version], currentBuildNumber < desiredBuildNumber ? @"an older" : @"a different", [currentListItem version]) == NSOKButton)
			{
				[self setJoiningServer:server];
				[self downloadMod:mapIdentifier];
			}
		}
		else if (NSRunAlertPanel(@"Modded Game",
							     @"Do you want to install %@ in order to join this game?",
							     @"Install", @"Cancel", nil, [listItem name]) == NSOKButton)
		{
			[self setJoiningServer:server];
			[self downloadMod:mapIdentifier];
		}
	}
}

- (void)openURL:(NSString *)url
{
	if ([self isInitiated])
	{
		NSString *prefix = @"halomdinstall://";
		if ([url hasPrefix:prefix])
		{
			[self installOnlineModWithIdentifier:[url substringFromIndex:[prefix length]]];
		}
	}
	else
	{
		[self setUrlToOpen:url];
	}
}

- (void)initiateAndForceDownloadList:(NSNumber *)shouldForceDownloadList
{	
	[self makeModMenuItems];
	[self makeModsList]; // In case the file doesn't download, use local copy
	
	[self makePluginMenuItems];
	
	id dateLastChecked = [[NSUserDefaults standardUserDefaults] objectForKey:MODS_LIST_DOWNLOAD_TIME_KEY];
	if ([shouldForceDownloadList boolValue] || ![[NSFileManager defaultManager] fileExistsAtPath:MODS_LIST_PATH] || [dateLastChecked isKindOfClass:[NSString class]] || [[NSDate date] timeIntervalSinceDate:dateLastChecked] > 10.0 * 60)
	{
		if ([shouldForceDownloadList boolValue])
		{
			NSLog(@"Forcing mod list download...");
		}
		[self downloadModList];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:MODS_LIST_DOWNLOAD_TIME_KEY];
	}
	else
	{
		[self stopAndStartDownloadModListTimer];
	}
	
	SCEvents *events = [[SCEvents alloc] init];
	[events setDelegate:self];
	
	NSArray *watchingPaths = [NSArray arrayWithObjects:MAPS_DIRECTORY, PLUGINS_DIRECTORY, PLUGINS_DISABLED_DIRECTORY, nil];
	[events startWatchingPaths:watchingPaths];
	
	[self setIsInitiated:YES];
	
	if ([self urlToOpen])
	{
		[self openURL:[self urlToOpen]];
		[self setUrlToOpen:nil];
	}
}

- (void)pathWatcher:(SCEvents *)pathWatcher eventOccurred:(SCEvent *)event
{
	if ([event.eventPath isEqualToString:MAPS_DIRECTORY])
	{
		[self makeModMenuItems];
		[self updateModMenuTitles];
	}
	else
	{
		[self makePluginMenuItems];
	}
}

- (IBAction)cancelInstallation:(id)sender
{
	if ([self modDownload])
	{
		[[self modDownload] cancel];
		[self setModDownload:nil];
		
		if ([self currentDownloadingPatch] || [self currentDownloadingMapIdentifier])
		{
			NSString *destination = [self currentDownloadingPatch] ? MOD_PATCH_DOWNLOAD_FILE : MOD_DOWNLOAD_FILE;
			if ([[NSFileManager defaultManager] fileExistsAtPath:destination])
			{
				[[NSFileManager defaultManager] removeItemAtPath:destination error:NULL];
			}
		}
		
		[self setCurrentDownloadingMapIdentifier:nil];
		[self setCurrentDownloadingPatch:nil];
		[appDelegate setStatus:nil];
		[cancelButton setHidden:YES];
		[refreshButton setHidden:NO];
	}
}

- (IBAction)revealMapsInFinder:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile:MAPS_DIRECTORY
					 inFileViewerRootedAtPath:[[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"GameData"]];
}

@end
