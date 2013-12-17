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

#ifdef DEBUG
	#define MULTIPLAYER_CODES_URL [NSURL URLWithString:@"http://halomd.macgamingmods.com/mods/mods_debug.json.gz"]
#else
	#define MULTIPLAYER_CODES_URL [NSURL URLWithString:@"http://halomd.macgamingmods.com/mods/mods.json.gz"]
#endif

#define MOD_DOWNLOAD_URL [NSURL URLWithString:[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/%@.zip", [self currentDownloadingMapIdentifier]]]
#define MOD_DOWNLOAD_FILE [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_download_file.zip"]

#define MOD_PATCH_DOWNLOAD_URL [NSURL URLWithString:[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/%@", [[self currentDownloadingPatch] path]]]
#define MOD_PATCH_DOWNLOAD_FILE [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_download_file.mdpatch"]

#define PLUGIN_DOWNLOAD_URL [NSURL URLWithString:[[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/plug-ins/%@.zip", [[self currentDownloadingPlugin] name]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
#define PLUGIN_DOWNLOAD_FILE [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_download_plugin.zip"]

#define PLUGINS_DIRECTORY [[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"PlugIns"]
#define PLUGINS_DISABLED_DIRECTORY [[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"PlugIns (Disabled)"]

#define BS_PATCH_PATH @"/usr/bin/bspatch"

@implementation MDModsController

@synthesize modMenuItems;
@synthesize modListDictionary;
@synthesize pluginMenuItems;
@synthesize pluginListDictionary;
@synthesize currentDownloadingMapIdentifier;
@synthesize isInitiated;
@synthesize modDownload;
@synthesize urlToOpen;
@synthesize didDownloadModList;
@synthesize pendingDownload;
@synthesize isWritingUI;
@synthesize currentDownloadingPatch;
@synthesize currentDownloadingPlugin;
@synthesize joiningServer;
@synthesize pendingPlugins;

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

- (BOOL)addPluginAtPath:(NSString *)filename preferringEnabledState:(BOOL)preferringEnabledState
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
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DISABLED_DIRECTORY])
	{
		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:PLUGINS_DISABLED_DIRECTORY withIntermediateDirectories:NO attributes:nil error:&error])
		{
			NSLog(@"Failed to create PlugIns disabled directory: %@", error);
			return NO;
		}
	}
	
	NSString *enabledPath = [PLUGINS_DIRECTORY stringByAppendingPathComponent:[filename lastPathComponent]];
	BOOL existedAtEnabledPath = [[NSFileManager defaultManager] fileExistsAtPath:enabledPath];
	if (existedAtEnabledPath)
	{
		[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
													 source:PLUGINS_DIRECTORY
												destination:@""
													  files:[NSArray arrayWithObject:[filename lastPathComponent]]
														tag:0];
	}
	
	NSString *disabledPath = [PLUGINS_DISABLED_DIRECTORY stringByAppendingPathComponent:[filename lastPathComponent]];
	BOOL existedAtDisabledPath = [[NSFileManager defaultManager] fileExistsAtPath:disabledPath];
	if (existedAtDisabledPath)
	{
		[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
													 source:PLUGINS_DISABLED_DIRECTORY
												destination:@""
													  files:[NSArray arrayWithObject:[filename lastPathComponent]]
														tag:0];
	}
	
	NSString *destination = nil;
	if (existedAtDisabledPath)
	{
		destination = disabledPath;
	}
	else if (existedAtEnabledPath)
	{
		destination = enabledPath;
	}
	else if (preferringEnabledState)
	{
		destination = enabledPath;
	}
	else
	{
		destination = disabledPath;
	}
	
	NSError *error = nil;
	if (![[NSFileManager defaultManager] moveItemAtPath:filename toPath:destination error:&error])
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
	NSString *normalPath = [PLUGINS_DIRECTORY stringByAppendingPathComponent:[pluginItem.name stringByAppendingPathExtension:@"mdplugin"]];
	NSString *disabledPath = [PLUGINS_DISABLED_DIRECTORY stringByAppendingPathComponent:[pluginItem.name stringByAppendingPathExtension:@"mdplugin"]];
	
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

// Prevent infoDictionary bundle caching if possible
- (NSDictionary *)infoDictionaryFromBundle:(NSBundle *)bundle
{
	NSString *infoPath = [[[bundle bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Info.plist"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath])
	{
		return [NSDictionary dictionaryWithContentsOfFile:infoPath];
	}
	return [bundle infoDictionary];
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
				NSDictionary *infoDictionary = [self infoDictionaryFromBundle:pluginBundle];
				NSNumber *globalPluginValue = [infoDictionary objectForKey:@"MDGlobalPlugin"];
				NSNumber *mapPluginValue = [infoDictionary objectForKey:@"MDMapPlugin"];
				NSUInteger buildNumber = [[infoDictionary objectForKey:@"CFBundleVersion"] integerValue];
				if (buildNumber > 0 && ([globalPluginValue boolValue] || [mapPluginValue boolValue]))
				{
					MDPluginListItem *pluginItem = [[MDPluginListItem alloc] init];
					
					pluginItem.enabled = enabled;
					pluginItem.globalMode = [globalPluginValue boolValue];
					pluginItem.mapMode = [mapPluginValue boolValue];
					
					pluginItem.name = [file stringByDeletingPathExtension];
					pluginItem.build = buildNumber;
					pluginItem.version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
					
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
			if ([[menuItem representedObject] globalMode])
			{
				[pluginsMenu removeItem:menuItem];
			}
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
	
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
	NSArray *sortedItems = [newPluginItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	BOOL addedPlugins = NO;
	if (sortedItems.count > 0)
	{
		for (MDPluginListItem *pluginItem in newPluginItems)
		{
			NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:pluginItem.name action:@selector(enablePlugin:) keyEquivalent:@""];
			newMenuItem.representedObject = pluginItem;
			newMenuItem.target = self;
			
			if (pluginItem.globalMode)
			{
				[pluginsMenu addItem:newMenuItem];
				addedPlugins = YES;
			}
			
			[[self pluginMenuItems] addObject:newMenuItem];
			[newMenuItem release];
		}
	}
	
	if (!addedPlugins)
	{
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"No Available Plug-Ins" action:@selector(doNothing:) keyEquivalent:@""];
		[menuItem setEnabled:NO];
		[pluginsMenu addItem:menuItem];
		[menuItem release];
	}
}

- (BOOL)reportWhatIsInstalling
{
	BOOL hadToReport = NO;
	
	if ([self currentDownloadingMapIdentifier] != nil)
	{
		NSRunAlertPanel(@"Installation in Progress",
						@"You are currently installing %@. Please try again when the installation finishes.",
						@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
		hadToReport = YES;
	}
	else if ([self currentDownloadingPlugin] != nil)
	{
		NSRunAlertPanel(@"Installation in Progress",
						@"You are currently installing %@. Please try again when the installation finishes.",
						@"OK", nil, nil, [[self currentDownloadingPlugin] name]);
		hadToReport = YES;
	}
	
	return hadToReport;
}

- (void)installOnlineModWithIdentifier:(NSString *)identifier
{
	if (![self reportWhatIsInstalling])
	{
		[self downloadMod:identifier];
	}
}

- (void)installOnlineMod:(id)sender
{
	[self installOnlineModWithIdentifier:[[sender representedObject] identifier]];
}

- (void)installOnlinePlugin:(MDPluginListItem *)plugin
{
	if (![self reportWhatIsInstalling])
	{
		[self downloadPlugin:plugin];
	}
}

- (void)installPluginsWithNames:(NSArray *)pluginNamesToInstall
{
	NSMutableArray *plugins = [NSMutableArray array];
	for (NSString *pluginName in pluginNamesToInstall)
	{
		MDPluginListItem *plugin = [pluginListDictionary objectForKey:pluginName];
		if (plugin != nil)
		{
			[plugins addObject:plugin];
		}
	}
	
	if (plugins.count > 0)
	{
		[self downloadPlugin:[plugins objectAtIndex:0]];
		if (plugins.count > 1)
		{
			[self setPendingPlugins:plugins];
		}
	}
}

- (void)installPlugin:(id)sender
{
	[self installOnlinePlugin:[sender representedObject]];
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

- (NSDictionary *)dictionaryFromJSONPath:(NSString *)jsonPath
{
	NSDictionary *dictionary = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:jsonPath])
	{
		NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
		if (jsonData != nil)
		{
			Class jsonSerializationClass = NSClassFromString(@"NSJSONSerialization");
			if (jsonSerializationClass != nil)
			{
				NSError *error = nil;
				dictionary = [jsonSerializationClass JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
			}
			else
			{
				dictionary = [[JSONDecoder decoder] objectWithData:jsonData];
			}
		}
	}
	return dictionary;
}

- (void)makeModsList
{
	NSDictionary *modsDictionary = [[self dictionaryFromJSONPath:MODS_LIST_PATH] objectForKey:@"Mods"];
	if (modsDictionary == nil)
	{
		NSLog(@"Mods: Failed to load %@", MODS_LIST_PATH);
	}
	else
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
		
		for (NSDictionary *modDictionary in modsDictionary)
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
			NSArray *plugins = [modDictionary objectForKey:@"plug-ins"];
			if (plugins == nil)
			{
				plugins = [NSArray array];
			}
			[listItem setPlugins:plugins];
			
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

- (void)makePluginsList
{
	NSDictionary *pluginsDictionary = [[self dictionaryFromJSONPath:MODS_LIST_PATH] objectForKey:@"Plug-ins"];
	[self setPluginListDictionary:[NSMutableDictionary dictionary]];
	
	if (pluginsDictionary == nil)
	{
		NSLog(@"Plug-ins: Failed to load %@", MODS_LIST_PATH);
		[self removeAllItemsFromMenu:onlinePluginsMenu];
	}
	else
	{
		[self removeAllItemsFromMenu:onlinePluginsMenu];
		
		NSMutableArray *pluginItems = [NSMutableArray array];
		
		for (NSDictionary *pluginDictionary in pluginsDictionary)
		{
			NSString *name = [pluginDictionary objectForKey:@"name"];
			NSString *description = [pluginDictionary objectForKey:@"description"];
			NSUInteger buildNumber = [[pluginDictionary objectForKey:@"build"] integerValue];
			NSString *version = [pluginDictionary objectForKey:@"version"];
			BOOL globalMode = [[pluginDictionary objectForKey:@"MDGlobalPlugin"] boolValue];
			BOOL mapMode = [[pluginDictionary objectForKey:@"MDMapPlugin"] boolValue];
			
			MDPluginListItem *newItem = [[MDPluginListItem alloc] init];
			newItem.name = name;
			newItem.description = description;
			newItem.build = buildNumber;
			newItem.version = version;
			newItem.mapMode = mapMode;
			newItem.globalMode = globalMode;
			
			if (newItem.globalMode)
			{
				[pluginItems addObject:newItem];
			}
			
			if (newItem.globalMode || newItem.mapMode)
			{
				[pluginListDictionary setObject:newItem forKey:name];
			}
			
			[newItem release];
		}
		
		NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
		NSArray *sortedPlugins = [pluginItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		
		for (MDPluginListItem *plugin in sortedPlugins)
		{
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:plugin.name action:@selector(installPlugin:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setToolTip:plugin.description];
			[menuItem setRepresentedObject:plugin];
			
			[onlinePluginsMenu addItem:menuItem];
			
			[menuItem release];
		}
	}
	
	for (NSMenuItem *menuItem in [self pluginMenuItems])
	{
		MDPluginListItem *plugin = [menuItem representedObject];
		MDPluginListItem *onlinePlugin = [pluginListDictionary objectForKey:plugin.name];
		if (plugin == nil || onlinePlugin == nil || !plugin.globalMode)
		{
			continue;
		}
		
		if (onlinePlugin.description != nil)
		{
			plugin.description = onlinePlugin.description;
			[menuItem setToolTip:plugin.description];
		}
	}
}

- (BOOL)showModUpdateNoticeIfNeeded
{
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
	
	return [itemsToUpdate count] > 0;
}

- (void)showPluginUpdateNoticeIfNeeded
{
	NSMutableArray *itemsToUpdate = [NSMutableArray array];
	NSMutableArray *favorableItemsToUpdate = [NSMutableArray array];
	
	for (NSMenuItem *menuItem in [self pluginMenuItems])
	{
		MDPluginListItem *pluginItem = [menuItem representedObject];
		MDPluginListItem *onlinePluginItem = [pluginListDictionary objectForKey:[pluginItem name]];
		if (pluginItem == nil || onlinePluginItem == nil)
		{
			continue;
		}
		
		if (pluginItem.build < onlinePluginItem.build)
		{
			[itemsToUpdate addObject:pluginItem];
			if (pluginItem.globalMode && pluginItem.enabled)
			{
				[favorableItemsToUpdate addObject:pluginItem];
			}
		}
	}
	
	MDPluginListItem *randomItem = nil;
	if ([favorableItemsToUpdate count] > 0)
	{
		randomItem = [favorableItemsToUpdate objectAtIndex:rand() % [favorableItemsToUpdate count]];
	}
	else if ([itemsToUpdate count] > 0)
	{
		randomItem = [itemsToUpdate objectAtIndex:rand() % [itemsToUpdate count]];
	}
	
	if (randomItem != nil)
	{
		NSAttributedString *statusString =  [NSAttributedString MDHyperlinkFromString:[NSString stringWithFormat:@"Update %@ (Plug-in)", [randomItem name]] withURL:[NSURL URLWithString:[[NSString stringWithFormat:@"halomdplugininstall://%@", [randomItem name]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		
		[appDelegate setStatus:statusString];
	}
}

- (void)showUpdateNoticeIfNeeded
{
	if ([appDelegate isQueryingServers] || [self currentDownloadingMapIdentifier] || [self currentDownloadingPlugin])
	{
		[self performSelector:@selector(showUpdateNoticeIfNeeded) withObject:nil afterDelay:10.0];
		return;
	}
	
	if (![self showModUpdateNoticeIfNeeded])
	{
		[self showPluginUpdateNoticeIfNeeded];
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

- (NSString *)directoryNameFromRequest:(NSURLRequest *)request
{
	return [[[[request URL] absoluteString] stringByDeletingLastPathComponent] lastPathComponent];
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
		[self makePluginsList];
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
	else if ([[self directoryNameFromRequest:download.request] isEqualToString:@"mods"])
	{
		NSString *unzipDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_Unzip"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:unzipDirectory])
		{
			[[NSFileManager defaultManager] removeItemAtPath:unzipDirectory error:nil];
		}
		
		BOOL addedMod = NO;
		
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
						if ([self pendingPlugins] == nil && (![[appDelegate window] isKeyWindow] || ![NSApp isActive]))
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
						
						addedMod = [self addModAtPath:[unzipDirectory stringByAppendingPathComponent:file]];
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
		
		[appDelegate setStatus:nil];
		[cancelButton setHidden:YES];
		[refreshButton setHidden:NO];
		
		[self setModDownload:nil];
		
		NSArray *plugins = [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] plugins];
		if (plugins != nil && plugins.count > 0)
		{
			[self setCurrentDownloadingMapIdentifier:nil];
			[self installPluginsWithNames:plugins];
		}
		else
		{
			[self setCurrentDownloadingMapIdentifier:nil];
		}
		
		if (!addedMod)
		{
			[self setJoiningServer:nil];
		}
		else
		{
			if ([self pendingPlugins] == nil)
			{
				if ([[appDelegate window] isKeyWindow] && [NSApp isActive] && [self joiningServer])
				{
					[appDelegate joinServer:[self joiningServer]	];
				}
				[self setJoiningServer:nil];
			}
		}
	}
	else if ([[self directoryNameFromRequest:download.request] isEqualToString:@"patches"])
	{
		NSString *baseMapPath = [self originalMapPathFromIdentifier:[[self currentDownloadingPatch] baseIdentifier]];
		
		BOOL addedMod = NO;
		
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
				if ([self pendingPlugins] == nil && (![[appDelegate window] isKeyWindow] || ![NSApp isActive]))
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
				
				addedMod = [self addModAtPath:newMapPath];
			}
			else
			{
				NSRunAlertPanel(@"Mod Installation Failed",
								@"%@ failed to install. Perhaps the downloaded patch file was corrupted.",
								@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
			}
			
			[[NSFileManager defaultManager] removeItemAtPath:MOD_PATCH_DOWNLOAD_FILE error:nil];
		}
		
		[appDelegate setStatus:nil];
		[cancelButton setHidden:YES];
		[refreshButton setHidden:NO];
		
		[self setModDownload:nil];
		
		[self setCurrentDownloadingPatch:nil];
		
		NSArray *plugins = [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] plugins];
		if (plugins != nil && plugins.count > 0)
		{
			[self setCurrentDownloadingMapIdentifier:nil];
			[self installPluginsWithNames:plugins];
		}
		else
		{
			[self setCurrentDownloadingMapIdentifier:nil];
		}
		
		if (!addedMod)
		{
			[self setJoiningServer:nil];
		}
		else
		{
			if ([self pendingPlugins] == nil)
			{
				if ([[appDelegate window] isKeyWindow] && [NSApp isActive] && [self joiningServer])
				{
					[appDelegate joinServer:[self joiningServer]	];
				}
				[self setJoiningServer:nil];
			}
		}
	}
	else if ([[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"])
	{
		NSString *unzipDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_Plugin_Unzip"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:unzipDirectory])
		{
			[[NSFileManager defaultManager] removeItemAtPath:unzipDirectory error:nil];
		}
		
		BOOL addedPlugin = NO;
		
		if ([[NSFileManager defaultManager] createDirectoryAtPath:unzipDirectory withIntermediateDirectories:NO attributes:nil error:nil])
		{
			NSTask *unzipTask = [[NSTask alloc] init];
			
			[unzipTask setLaunchPath:@"/usr/bin/unzip"];
			[unzipTask setArguments:[NSArray arrayWithObjects:@"-o", @"-q", @"-d", unzipDirectory, PLUGIN_DOWNLOAD_FILE, nil]];
			
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
					if ([[file pathExtension] isEqualToString:@"mdplugin"] && ![[file lastPathComponent] hasPrefix:@"."])
					{
						addedPlugin = [self addPluginAtPath:[unzipDirectory stringByAppendingPathComponent:file] preferringEnabledState:[self pendingPlugins] == nil];
						break;
					}
				}
			}
			else
			{
				NSRunAlertPanel(@"Plug-in Installation Failed",
								@"%@ failed to install. Perhaps the downloaded file was corrupted.",
								@"OK", nil, nil, [[self currentDownloadingPlugin] name]);
			}
			
			[[NSFileManager defaultManager] removeItemAtPath:unzipDirectory error:nil];
		}
		
		[appDelegate setStatus:nil];
		
		[self setModDownload:nil];
		
		[cancelButton setHidden:YES];
		[refreshButton setHidden:NO];
		[self setCurrentDownloadingPlugin:nil];
		
		if (!addedPlugin)
		{
			[self setPendingPlugins:nil];
		}
		else
		{
			if ([[self pendingPlugins] count] > 0)
			{
				[[self pendingPlugins] removeObjectAtIndex:0];
				if ([[self pendingPlugins] count] == 0)
				{
					[self setPendingPlugins:nil];
				}
				else
				{
					[self downloadPlugin:[[self pendingPlugins] objectAtIndex:0]];
				}
			}
		}
		
		if ([self pendingPlugins] == nil && [self joiningServer] != nil)
		{
			if (addedPlugin && [[appDelegate window] isKeyWindow] && [NSApp isActive])
			{
				[appDelegate joinServer:[self joiningServer]];
			}
			[self setJoiningServer:nil];
		}
	}
	
	[download release];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	if (![download.request.URL isEqual:MULTIPLAYER_CODES_URL] && ([[self directoryNameFromRequest:download.request] isEqualToString:@"mods"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"patches"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"]))
	{
		// Ensure currentContentLength won't exceed expectedContentLength
		if (currentContentLength < expectedContentLength)
		{
			currentContentLength += length;
			if (currentContentLength > expectedContentLength)
			{
				currentContentLength = expectedContentLength;
			}
			if ([[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"])
			{
				[appDelegate setStatusWithoutWait:[NSString stringWithFormat:@"Installing Plug-in %@... (%d%%)", [[self currentDownloadingPlugin] name], (int)((100.0 * currentContentLength) / expectedContentLength)]];
			}
			else
			{
				[appDelegate setStatusWithoutWait:[NSString stringWithFormat:@"Installing %@... (%d%%)", [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name], (int)((100.0 * currentContentLength) / expectedContentLength)]];
			}
		}
	}
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	if (![download.request.URL isEqual:MULTIPLAYER_CODES_URL] && ([[self directoryNameFromRequest:download.request] isEqualToString:@"mods"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"patches"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"]))
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
	
	if ([[[download request] URL] isEqual:MULTIPLAYER_CODES_URL])
	{
		isDownloadingModList = NO;
		[self setPendingDownload:nil];
	}
	else if ([[self directoryNameFromRequest:download.request] isEqualToString:@"mods"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"patches"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"])
	{
		NSString *destination = nil;
		
		if ([[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"])
		{
			destination = PLUGIN_DOWNLOAD_FILE;
		}
		else
		{
			destination = [self currentDownloadingPatch] ? MOD_PATCH_DOWNLOAD_FILE : MOD_DOWNLOAD_FILE;
		}
		
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
			if ([[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"])
			{
				NSRunAlertPanel(@"Plug-in Download Failed",
								@"%@ failed to finish downloading.",
								@"OK", nil, nil, [[self currentDownloadingPlugin] name]);
			}
			else
			{
				NSRunAlertPanel(@"Mod Download Failed",
								@"%@ failed to finish downloading.",
								@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
			}
			
			[self setCurrentDownloadingMapIdentifier:nil];
			[self setCurrentDownloadingPatch:nil];
			[self setCurrentDownloadingPlugin:nil];
			
			[appDelegate setStatus:nil];
			
			[cancelButton setHidden:YES];
			[refreshButton setHidden:NO];
			[self setModDownload:nil];
			[self setPendingPlugins:nil];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:destination])
			{
				[[NSFileManager defaultManager] removeItemAtPath:destination error:NULL];
			}
		}
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

- (void)downloadPlugin:(MDPluginListItem *)plugin
{
	[self setCurrentDownloadingPlugin:plugin];
	
	[appDelegate setStatus:[NSString stringWithFormat:@"Installing %@ (Plug-in)...", plugin.name]];
	
	[resumeTimeoutDate release];
	resumeTimeoutDate = nil;
	
	NSURLRequest *request = [NSURLRequest requestWithURL:PLUGIN_DOWNLOAD_URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
	[download setDestination:PLUGIN_DOWNLOAD_FILE allowOverwrite:YES];
	[download setDeletesFileUponFailure:YES];
	[self setModDownload:download];
}

- (void)requestModDownload:(NSString *)mapIdentifier andJoinServer:(MDServer *)server
{
	MDModListItem *listItem = [modListDictionary objectForKey:mapIdentifier];
	if (![self reportWhatIsInstalling])
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

- (BOOL)requestPluginDownloadIfNeededFromMod:(NSString *)mapIdentifier andJoinServer:(MDServer *)server
{
	if ([self reportWhatIsInstalling]) return YES;
	
	MDModListItem *modItem = [modListDictionary objectForKey:mapIdentifier];
	
	NSArray *pluginNames = [modItem plugins];
	NSMutableArray *pluginNamesToInstall = [NSMutableArray array];
	
	BOOL needsInstalling = NO;
	
	for (NSString *pluginName in pluginNames)
	{
		MDPluginListItem *matchingPlugin = nil;
		for (NSMenuItem *menuItem in [self pluginMenuItems])
		{
			MDPluginListItem *pluginItem = [menuItem representedObject];
			if ([pluginItem.name isEqualToString:pluginName])
			{
				matchingPlugin = pluginItem;
				break;
			}
		}
		
		if (matchingPlugin == nil)
		{
			[pluginNamesToInstall addObject:pluginName];
			needsInstalling = YES;
			continue;
		}
		
		MDPluginListItem *onlineItem = [pluginListDictionary objectForKey:pluginName];
		if (onlineItem == nil || onlineItem.build == 0) continue;
		
		if (matchingPlugin.build < onlineItem.build)
		{
			[pluginNamesToInstall addObject:pluginName];
		}
	}
	
	if (pluginNamesToInstall.count > 0)
	{
		if (NSRunAlertPanel(@"Modded Game",
							@"Do you want to %@ %d plug-in%@ in order to join this game?",
							@"Install", @"Cancel", nil, needsInstalling ? @"install" : @"update", pluginNamesToInstall.count, pluginNamesToInstall.count != 1 ? @"s" : @"") == NSOKButton)
		{
			[self installPluginsWithNames:pluginNamesToInstall];
		}
	}
	
	return pluginNamesToInstall.count > 0;
}

- (void)openURL:(NSString *)url
{
	if ([self isInitiated])
	{
		NSString *modPrefix = @"halomdinstall://";
		NSString *pluginPrefix = @"halomdplugininstall://";
		if ([url hasPrefix:modPrefix])
		{
			[self installOnlineModWithIdentifier:[url substringFromIndex:[modPrefix length]]];
		}
		else if ([url hasPrefix:pluginPrefix])
		{
			[self installPluginsWithNames:[NSArray arrayWithObject:[[url substringFromIndex:[pluginPrefix length]] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
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
	[self makePluginsList];
	
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
		else if ([self currentDownloadingPlugin])
		{
			NSString *destination = PLUGIN_DOWNLOAD_FILE;
			if ([[NSFileManager defaultManager] fileExistsAtPath:destination])
			{
				[[NSFileManager defaultManager] removeItemAtPath:destination error:NULL];
			}
		}
		
		[self setCurrentDownloadingMapIdentifier:nil];
		[self setCurrentDownloadingPatch:nil];
		[self setCurrentDownloadingPlugin:nil];
		[self setPendingPlugins:nil];
		[self setJoiningServer:nil];
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
